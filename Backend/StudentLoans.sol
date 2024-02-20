//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StudentLoan{

    mapping (address => uint) balances; 
    mapping(address => Student) public students;
    mapping(address => Investor) public investors;

    mapping(address => bool) public hasOngoingLoan;
    mapping(address => bool) public hasOngoingApplication;
    mapping(address => bool) public hasOngoingInvestment;

    mapping (uint => LoanApplication) public applications;
    mapping (uint => Loan) public loans;   

    uint numApplications;
    uint numLoans;

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
        uint appId;
    }

    function createInvestor(string memory name) public {
        Investor memory investor;
        investor.name = name;
        investor.investor_public_key = msg.sender;
        investor.EXISTS = true;
        require(students[msg.sender].EXISTS != true);
        investors[msg.sender] = investor;

        
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Initial balance

    }

    function createStudent(string memory name) public{
        Student memory student;
        student.name = name;
        student.student_public_key = msg.sender;
        student.EXISTS = true;
        require(investors[msg.sender].EXISTS != true);
        students[msg.sender] = student;

        
        hasOngoingApplication[msg.sender] = false;
        balances[msg.sender] = 0; // Initial balance
    }

    function createApplication(uint interest_rate, uint credit_amount) public {
        require(hasOngoingLoan[msg.sender] == false);
        require(isStudent(msg.sender));
        applications[numApplications] = LoanApplication(true, numApplications, msg.sender, credit_amount, interest_rate);
        numApplications += 1;  
        hasOngoingApplication[msg.sender] = true;
    }

    function grantLoan(uint appId, uint amount) public {
        
        require(balances[msg.sender] >= amount); //Check sufficient balance
        require(hasOngoingInvestment[msg.sender] == false);  //Per contract we allow one investment per investor 

        // Take from sender and give to reciever
        balances[msg.sender] -= amount;
        balances[applications[appId].student] += amount;

        // Populate loan object
        loans[numLoans] = Loan(true, numLoans, applications[appId].student, msg.sender, applications[appId].interest_rate,
        amount, amount, 0, appId);
        numLoans += 1;
        
        applications[appId].credit_amount -= amount;
        hasOngoingLoan[applications[appId].student] = true;
        hasOngoingInvestment[msg.sender] = true;
        
        if(applications[appId].credit_amount == 0) { 
            applications[appId].openApp = false;
        }
   
    }  



     function repayLoan(uint amount, uint estimatedInterest,  uint id_) public {
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
    

    receive() external payable {
        // custom function code
    }


    // function withdraw(uint amount) public {
    //     require(amount <= balances[msg.sender]);
    //     balances[msg.sender] -= amount;  //safemath
    //     msg.sender.call{value : amount, gas : 50000}('');
    // }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }


    function isInvestor(address account) view public returns (bool) {return investors[account].EXISTS;}
    function isStudent(address account) view public returns (bool) {return students[account].EXISTS;}
    function getTime() view public returns (uint) {return block.timestamp;}
}