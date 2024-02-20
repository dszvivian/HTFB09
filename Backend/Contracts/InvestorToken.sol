//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './StudentLoans.sol';

contract InvestorToken{
    constructor() {
        owner = payable(msg.sender);
        for_sale = false;
        ask_price = 0;
    }
    
    address payable owner;
    address payable stu_loan_address;
    bool for_sale;
    uint ask_price;
        
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

    function stuLoanAddress(address payable _address) public returns (address) {
        stu_loan_address = _address;
        return stu_loan_address;
    }
    
    //We now specify functions which interact with the StuLoan contract. The functions are mirrored and explained in the StuLoan contract
    function createInvestor(string memory name) public {
        require(msg.sender == owner);
        StudentLoan c = StudentLoan(stu_loan_address);
        c.createInvestor(name);
    }
    
    function grantLoan(uint appId, uint amount) public {
        require(msg.sender == owner);
        StudentLoan c = StudentLoan(stu_loan_address);
        c.grantLoan(appId, amount);
    }
    
    function viewBalanceInLoan() view public returns (uint){
        require(msg.sender == owner);
        StudentLoan c = StudentLoan(stu_loan_address);
        return c.viewBalance();
    }
    
    function depositToLoan() payable external {
        require(msg.sender == owner);
        stu_loan_address.call{gas: 50000, value: msg.value}('');
    }
    
    
    function withdrawFromLoan(uint amount) public {
        require(msg.sender == owner);
        StudentLoan c = StudentLoan(stu_loan_address);
        c.withdraw(amount);
    }
    

    function getLoanData() view public returns (uint[] memory , address, address){
        require(msg.sender == owner);
        StudentLoan c = StudentLoan(stu_loan_address);
        uint index = c.invFindLoans();
        return c.getLoanData(index);
        
    }
    
    function getNumApplications() view public returns (uint) { 
        StudentLoan c = StudentLoan(stu_loan_address);
        return c.getNumApplications();
    }
    
    function getApplicationData(uint index)  view public returns (uint, uint, uint, string memory, address) { 
        StudentLoan c = StudentLoan(stu_loan_address);
        return c.getApplicationData(index);
    }
    
    //Below we define the functions which will provide the functionality to the contract.
    
    function getTime() view public returns (uint) {return block.timestamp;}
    
    function withdraw(uint amount) noReentrancy public {
        withdrawFromLoan(viewBalanceInLoan());
        require(amount <= address(this).balance);
        owner.transfer(amount);
    }
    
     function viewBalance() view public returns (uint){
        return address(this).balance;
    }
    
    //We now define the function which allow the contract to be traded. These functions work by allowing a tranfer of ownership
    //in exchange for an amount of Wei specified by the owner/seller. When the owner/seller decides to sell this contract any 
    //outstanding balance in the StuLoan contract is withdrawn.

    function sell(uint askprice) public {
        require(msg.sender == owner);
        withdrawFromLoan(viewBalanceInLoan());
        for_sale = true;
        ask_price = askprice;
    }
    
    function viewAskPrice() public view returns (uint) {
        return ask_price;
        
    }
    
    //When the contract is bought any balance outstanding in this contract is sent to the seller.
    
    function buy() payable public {
        require(for_sale == true);
        require(msg.value == ask_price);
        address(this).call{value : msg.value, gas : 50000}('');
        withdraw(viewBalance());
        owner = payable(msg.sender);
        for_sale = false;
    }
    
    function removeSale() public {
        require(msg.sender == owner);
        for_sale = false;
    }
    
    fallback  () external payable {
    }

    receive() external payable {
        // custom function code
    }
}