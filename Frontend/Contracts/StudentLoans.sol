//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StudentLoan {

    // Variables
    mapping (address => uint) balances; // Either investor or student => balance
    mapping (address => Investor) public investors; // Investor public key => Investor
    mapping (address => Student) public students; // Student public key => Student

    mapping(address => bool) hasOngoingInvestment;  //Does this address have an investment?
    mapping(address => bool) hasOngoingLoan;        //Does this address have an outstanding loan?
    mapping(address => bool) hasOngoingApplication; //Does this address have an ongoing application process?

    mapping (uint => LoanApplication) public applications;
    mapping (uint => Loan) public loans;

    //Counters, which always increment with creation of each new application or loan.
    uint numApplications;
    uint numLoans;

    // Structures
    struct Investor{
        address investor_public_key;
        string name;
        bool EXISTS;
    }
    
    struct Student{
        address student_public_key;
        string name;
        bool EXISTS;
    }
    
    struct LoanApplication{
        bool openApp;
        uint applicationId;
        address student;
        uint credit_amount; // Loan amount
        uint interest_rate; //From form
        string RiskRating; // Encoded string with delimiters (~) CR1-CR10

    }
    
    struct Loan{
        bool openLoan;
        uint loanId;
        address student;
        address investor;
        uint interest_rate;
        uint principal_amount;
        uint original_amount;
        uint amount_paid;
        uint startTime;
        uint monthlyCheckpoint;
        uint appId;
    }
    
    //A modifier is defined to ensure the contract is safe from reentrancy attacks.
    bool locked;
    modifier noReentrancy() {
        require(
            !locked,
            "Reentrant call."
        );
        locked = true;
        _;
        locked = false;
    }

    //This function allows the creation of an investor object and it fills in the objects attributes.
    function createInvestor(string memory name) public {
        Investor memory investor;
        investor.name = name;
        investor.investor_public_key = msg.sender;
        investor.EXISTS = true;
        require (students[msg.sender].EXISTS != true); // A student cannot be an investor
        investors[msg.sender] = investor;
        hasOngoingInvestment[msg.sender] = false;
        balances[msg.sender] = 0; // Initial balance
    }
    
    //This function allows the creation of a student object and it fills in the objects attributes.
    function createStudent (string memory name) public {
        Student memory student;
        require(students[msg.sender].EXISTS == false);
        student.name = name;
        student.student_public_key = msg.sender;
        student.EXISTS = true; //change student.EXISTS flag to true
        require (investors[msg.sender].EXISTS != true); //Investor cannot be student
        students[msg.sender] = student;
        hasOngoingLoan[msg.sender] = false;
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Initial balance
    }
    

    //The first step is to apply for a student loan. 
    //This function allows the creation of an application object and it fills in the objects attributes.
    function createApplication(uint interest_rate, uint credit_amount, string memory RiskRating) public {
        require(hasOngoingLoan[msg.sender] == false);
        require(hasOngoingApplication[msg.sender] == false);
        require(isStudent(msg.sender));
        //application indexed by numApplication (a global counter which increases with every new application) is the new application
        applications[numApplications] = LoanApplication(true, numApplications, msg.sender, credit_amount, interest_rate, RiskRating);
        //increase the counter 
        numApplications += 1;
        //set bool flag of applicat address to signal he has an ongoing application
        hasOngoingApplication[msg.sender] = true;
    }
    
    
    //Next, if requirements are met, we need to turn the application into an ongoing loan. 
    //This function allows the creation of an investor object and it fills in the objects attributes, referring to the corresponding application object.
    function grantLoan(uint appId, uint amount) public {
        
        require(balances[msg.sender] >= amount); //Check sufficient balance
        require(hasOngoingInvestment[msg.sender] == false);  //Per contract we allow one investment per investor 

        // Take from sender and give to reciever
        balances[msg.sender] -= amount;
        balances[applications[appId].student] += amount;

        // Populate loan object
        loans[numLoans] = Loan(true, numLoans, applications[appId].student, msg.sender, applications[appId].interest_rate,
        amount, amount, 0, block.timestamp, 0, appId);
        numLoans += 1;
        
        applications[appId].credit_amount -= amount;
        hasOngoingLoan[applications[appId].student] = true;
        hasOngoingInvestment[msg.sender] = true;
        
        if(applications[appId].credit_amount == 0) { 
            applications[appId].openApp = false;
        }
   
    }    
    
    //This function allows a student to count how many active loans they have
    function countLoans() public view returns (uint)  {
        uint count = 0;
        for(uint i=0; i<=numLoans; i++)
        {
                if(loans[i].student == msg.sender)
                {
                    count ++;
                }
        }
         
        return count;
        
    }
    
    //This function allows a student to find the ids of the active loans they have
    function findLoans() public view returns (uint[] memory)  {
        
        uint[] memory active_loans = new uint[](countLoans());
        uint counter = 0;
        for(uint i=0; i<=numLoans; i++)
        {

            if(loans[i].student == msg.sender)
            {
                active_loans[counter] = i;
                counter ++;
          
            }
        }
        
        return active_loans;
        
    }
    
    //This function allows an investor to find the loan id of the InvestorToken they own
    function invFindLoans() public view returns (uint)  {
        uint id = 0;
        for(uint i=0; i<=numLoans; i++)
        {
        
                if(loans[i].investor == msg.sender)
                {
                    id = i;
                    break;
                }
        }
        return id;
    }
       
    //This function allows a student to repay their loan. Repayment here is handled within the StuLoan balances, and credit is shifted around between balances.
    //The function only decreases the principal_amount of the loan once interest for the period has been paid.
    function repayLoan(uint amount, uint estimatedInterest, uint timeSinceLastPayment, uint id_) public {
        //First check if the payer has enough money
        require(balances[msg.sender] >= amount);

        //Require that a loan is ongoing
        require(loans[id_].openLoan == true);
        
        //Get some params fromt the loan
        uint p = loans[id_].principal_amount;
        uint amountWithInterest = estimatedInterest;

        //Get just the interest for that month
        uint interest = amountWithInterest - p;

        //Payable amount should not exceed the amountWithInterest
        require(amountWithInterest>=amount);
        require(interest <= amount);

        // Update balance for interest first
        balances[msg.sender] -= interest;
        balances[loans[id_].investor] += interest;

        amount -= interest;
        loans[id_].monthlyCheckpoint += timeSinceLastPayment;
        loans[id_].amount_paid += interest;

        //Decrease principal after interest is paid
        if(amount>0)
        {
            loans[id_].principal_amount -= amount;
            loans[id_].amount_paid += amount;

            balances[msg.sender] -= amount;
            balances[loans[id_].investor] += amount;
        }

        if(loans[id_].principal_amount == 0)
        {
            loans[id_].openLoan = false;
            hasOngoingLoan[msg.sender] = false;
            hasOngoingApplication[msg.sender] = false;
            hasOngoingApplication[loans[id_].investor] = false;
            hasOngoingLoan[loans[id_].investor] = false;
        }
        
    }
    
    
    //The functions allow functionality to the contract. Users can deposit, withdraw, or view their balances.
    function viewBalance() view public returns (uint){
        return balances[msg.sender];
    }
    
    fallback () external payable {
        balances[msg.sender] += msg.value;
        
    }
    
    function withdraw(uint amount) noReentrancy public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;  //safemath
        msg.sender.call{value : amount, gas : 50000}('');
    }
    
    //Now we just need some functions to make it easier for the contract to interact with the outside world, ie Web3
    //Plus some functions we use as checks when creating students, investors, loans and applications.
    
    function ifApplicationOpen (uint index) view public returns (bool){
        if(applications[index].openApp) return true; else return false;
    }
    
    function ifLoanOpen(uint index) view public returns (bool){
        if (loans[index].openLoan == true) return true; else return false;
    }
    
    function getApplicationData(uint index) view public returns (uint, uint, uint, string memory, address){
        string memory RiskRating = applications[index].RiskRating;
        uint interest_rate = applications[index].interest_rate;
        uint credit_amount = applications[index].credit_amount;
        address student = applications[index].student;
        return (index, credit_amount, interest_rate,RiskRating, student);
    }
    
    
    function getLoanData(uint index) view public returns (uint[] memory, address, address){
        uint[] memory numericalData = new uint[](9);
        numericalData[0] = index;
        numericalData[1] = loans[index].interest_rate;
        numericalData[2] = loans[index].principal_amount;
        numericalData[3] = loans[index].original_amount;
        numericalData[4] = loans[index].amount_paid;
        numericalData[5] = loans[index].startTime;
        numericalData[6] = loans[index].monthlyCheckpoint;
        numericalData[7] = loans[index].appId;

        return (numericalData, loans[index].student, loans[index].investor);
    }
    
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function getNumApplications() view public returns (uint) { return numApplications;}
    function getNumLoans() view public returns (uint) { return numLoans;}
    function isInvestor(address account) view public returns (bool) {return investors[account].EXISTS;}
    function isStudent(address account) view public returns (bool) {return students[account].EXISTS;}
    function getTime() view public returns (uint) {return block.timestamp;}


    receive() external payable {
        // custom function code
    }

}