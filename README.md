
# code ที่ป้องกันการ lock เงินไว้ใน contract
ใน function forceEndGame()จะมี TIMEOUT = 5 minutes เพื่อเอาไว้ใช้ในการคืนเงิน
    
    payable(players[i]).transfer(reward);

# code ซ่อน choice และ commit
randomString เพื่อป้องกัน front-running และ ใช้ keccak256(abi.encodePacked(choice, randomString)) เพื่อซ่อนตัวเลือก ; ตัวเลือกที่ user เลือกจะเก็บไว้ใน mapping(address => uint) private player_choice;
ผู้เล่นต้องส่งค่า Commit Hash ของ (ตัวเลือก + ค่าลับ) ตอนเข้าร่วมเกม

    mapping(address => uint) private player_choice; // ทำเพื่อซ่อนตัวเลือก
    mapping(address => bytes32) public player_commit;

    require(getHash(keccak256(abi.encodePacked(choice, randomString))) == player_commit[msg.sender], "Invalid reveal");// เปิดตัวเลือกที่เลือก

# code จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคน
  if case มีแค่คนเดียวที่ commit แล้วอีกคนไม่มาเล่น หรือ ไม่มีอีกคนจริง → ระบบต้องคืนเงิน

    require(block.timestamp > startTime + TIMEOUT, "Timeout not reached yet");
    require(numInput < 2, "Game already resolved");

# code reveal และนำ choice มาตัดสินผู้ชนะ
  คนเล่นต้องส่งค่า commitHash = keccak256(abi.encodePacked(choice, randomString)) ตอน addPlayer()    เพื่อยืนยันว่าถูก add แล้ว เปิดเผยค่าโดยส่ง choice 

ป้องกันเกมค้าง
มี TIMEOUT = 5 minutes กำหนดเวลาสูงสุดสำหรับการเปิดเผยตัวเลือก
และ ถ้าหมดเวลาและยังมีคนไม่เปิดเผยตัวเลือก → เกมจบอัตโนมัติและคืนเงินให้เฉพาะผู้ที่เปิดเผยแล้ว
เล่นรอบใหม่ได้ จากการ _resetGame()

จำกัดผู้เล่น ไม่ให้คนเดิมเล่นซ้ำในรอบเดียวกัน และต้องมี 2 คนต่อรอบ
