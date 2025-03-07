// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./CommitReveal.sol";

contract RPS {

    TimeUnit public timeunit = new TimeUnit();
    uint256 public numPlayer = 0;
    uint256 public reward = 0;
    mapping(address => bytes32) public commitments; // Store committed moves
    mapping(address => uint256) public player_choice;
    mapping(address => bool) public player_not_played;
    address[] public players;
    uint256 public numInput = 0;

    address[] private player_allowed = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    modifier onlyPlayers() {
        require(msg.sender == players[0] || msg.sender == players[1], "Not a valid player");
        _;
    }

    function addPlayer() public payable {
        bool allowed = false;
        for (uint256 i = 0; i < player_allowed.length; i++) {
            if (msg.sender == player_allowed[i]) {
                allowed = true;
                break;
            }
        }
        require(allowed, "You're not allowed to join this game");
        require(numPlayer < 2, "Game full");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Player already added");
        }
        require(msg.value == 1 ether, "Must send 1 ETH");
        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;
    }

    function commitMove(bytes32 _commitment) external onlyPlayers {
        require(commitments[msg.sender] == bytes32(0), "Already committed");
        commitments[msg.sender] = _commitment;
    }

    function revealMove(uint256 choice, string memory salt) external onlyPlayers {
        require(commitments[msg.sender] != bytes32(0), "No commitment found");
        require(player_not_played[msg.sender], "Already revealed");
        require(keccak256(abi.encode(choice, salt)) == commitments[msg.sender], "Invalid reveal");

        require(
            choice == 0 ||
                choice == 1 ||
                choice == 2 ||
                choice == 3 ||
                choice == 4,
            "Invalid Choice"
        );

        player_choice[msg.sender] = choice;
        player_not_played[msg.sender] = false;
        numInput++;

        if (numInput == 2) {
            _checkWinnerAndPay();
        }
    }

    function getHash(uint256 choice, string memory salt) public pure returns (bytes32) {
        return keccak256(abi.encode(choice, salt));
    }

    function _checkWinnerAndPay() private {
        uint256 p0Choice = player_choice[players[0]];
        uint256 p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice + 1) % 5 == p1Choice || (p0Choice + 3) % 5 == p1Choice) {
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 5 == p0Choice || (p1Choice + 3) % 5 == p0Choice) {
            account0.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }
        resetGame();
    }

    function Callback() public payable {
        require(numPlayer == 1);
        require(timeunit.elapsedSeconds() > 3600);
        if (timeunit.elapsedSeconds() > 3600) {
            payable(players[0]).transfer(reward);
        }
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }

    function forceGame() public payable {
        require(numPlayer == 2);
        require(player_not_played[msg.sender] == false);
        require(timeunit.elapsedSeconds() > 7200);
        if (timeunit.elapsedSeconds() > 7200) {
            payable(msg.sender).transfer(reward);
        }
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }

    function resetGame() internal {
        delete commitments[players[0]];
        delete commitments[players[1]];
        delete player_choice[players[0]];
        delete player_choice[players[1]];
        numPlayer = 0;
        reward = 0;
        numInput = 0;
        delete players;
    }
}