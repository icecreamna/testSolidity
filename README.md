
# code ที่ป้องกันการ lock เงินไว้ใน contract
ใน function forceEndGame()จะมี TIMEOUT = 2 hours เพื่อเอาหาผู้ชนะ ถ้าอีกคนพยายามไม่ลง หลังกด forceEndGame คนที่ลงจะได้เงินเหมือนผู้ชนะ
    
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

# code ซ่อน choice และ commit
การใช้ Commit-Reveal Scheme ช่วยป้องกัน front-running โดยให้ผู้เล่นทำการ commit ค่า choice ของตนก่อน แล้วค่อยมา reveal ทีหลัง ฟังก์ชันนี้รับค่า _commitment ซึ่งเป็นค่า hash(choice, salt)
ค่านี้จะถูกเก็บไว้ใน CommitReveal contract โดยที่ไม่มีใครรู้ค่า choice จริงๆ _salt ใช้เพื่อป้องกันการคาดเดาค่าที่ commit ใช้สำหรับให้ผู้เล่นสร้างค่า hash ของ choice ก่อน commit
คำนวณค่า keccak256(abi.encodePacked(choice, salt))

    function commitMove(bytes32 _commitment, uint256 _choice, string memory _salt) external onlyPlayers {
    commitReveal.commitMove(msg.sender, _commitment, _choice, _salt);
    function getHash(uint256 choice, string memory salt) public view returns (bytes32) {
    return commitReveal.getHash(choice, salt);
    }}


    
# code จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคน
  หากมีผู้เล่นคนเดียว และ ผ่านไป 3600 วินาที (1 ชั่วโมง) เงินทั้งหมดจะถูกคืนให้กับผู้เล่นคนนั้น

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

# code reveal และนำ choice มาตัดสินผู้ชนะ
ตรวจสอบว่าผู้เล่นยังไม่ได้เปิดเผยค่า choiceตรวจสอบว่าค่า choice ที่เปิดเผยต้องถูกต้อง (เป็นค่าระหว่าง 0-4)เรียก commitReveal.reveal() เพื่อตรวจสอบว่าค่าที่เปิดเผยถูกต้องหรือไม่หากผู้เล่นทั้งสองเปิดเผยค่าแล้ว (numInput == 2) จะเรียก _checkWinnerAndPay() เพื่อหาผู้ชนะและแจกเงินรางวัล
    
       function revealMove(uint256 choice) external onlyPlayers {
    require(player_not_played[msg.sender], "Already revealed");
    require(
        choice == 0 ||
        choice == 1 ||
        choice == 2 ||
        choice == 3 ||
        choice == 4,
        "Invalid Choice"
    );
    require(commitReveal.reveal(msg.sender), "Invalid reveal");
    player_choice[msg.sender] = choice;
    player_not_played[msg.sender] = false;
    numInput++;

    if (numInput == 2) {
        _checkWinnerAndPay();
        }
    }

