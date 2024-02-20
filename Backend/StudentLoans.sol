//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StudentLoan{

    struct Investor{
        address investor_public_key;
    }

    struct Student{
        address student_public_key;
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
    }

    

}