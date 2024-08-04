// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CarbonCreditInvestment is Ownable {
    using Counters for Counters.Counter;

    IERC20 public carbonCreditToken;

    struct Company {
        string name;
        address walletAddress;
    }

    struct Investor {
        address walletAddress;
        uint256 amount;
    }

    struct Investment {
        Company mainCompany;
        uint256 targetAmount;
        uint256 raisedAmount;
        uint256 creditAmount;
        bool isCompleted;
        bool isVerified;
        bool isCreditsClaimed;
        Company[] participatingCompanies;
        Investor[] investors;
    }

    mapping(uint256 => Investment) public investments;
    Counters.Counter private _investmentIds;

    event InvestmentCreated(uint256 indexed investmentId, string companyName, address companyWallet, uint256 targetAmount);
    event InvestmentMade(uint256 indexed investmentId, address investor, uint256 amount);
    event InvestmentCompleted(uint256 indexed investmentId);
    event InvestmentVerified(uint256 indexed investmentId);
    event CreditsMinted(uint256 indexed investmentId, uint256 amount);
    event CreditsClaimed(uint256 indexed investmentId, address company, uint256 amount);
    event CompanyAdded(uint256 indexed investmentId, string companyName, address companyWallet);

    constructor(address _carbonCreditToken) Ownable() {
        carbonCreditToken = IERC20(_carbonCreditToken);
    }

    function createInvestment(string memory companyName, address companyWallet, uint256 targetAmount) external onlyOwner returns (uint256) {
    _investmentIds.increment();
    uint256 newInvestmentId = _investmentIds.current();
    
    Company memory mainCompany = Company({
        name: companyName,
        walletAddress: companyWallet
    });

    Investment storage newInvestment = investments[newInvestmentId];
    newInvestment.mainCompany = mainCompany;
    newInvestment.targetAmount = targetAmount;
    newInvestment.raisedAmount = 0;
    newInvestment.creditAmount = 0;
    newInvestment.isCompleted = false;
    newInvestment.isVerified = false;
    newInvestment.isCreditsClaimed = false;
    

    emit InvestmentCreated(newInvestmentId, companyName, companyWallet, targetAmount);
    return newInvestmentId;
}


    function addParticipatingCompany(uint256 investmentId, string memory companyName, address companyWallet) external onlyOwner {
        Company memory newCompany = Company({
            name: companyName,
            walletAddress: companyWallet
        });
        investments[investmentId].participatingCompanies.push(newCompany);
        emit CompanyAdded(investmentId, companyName, companyWallet);
    }

    function invest(uint256 investmentId, address investor, uint256 amount) external onlyOwner {
        Investment storage investment = investments[investmentId];
        require(!investment.isCompleted, "Investment round is completed");
        require(amount > 0, "Investment amount must be greater than 0");

        investment.investors.push(Investor({
            walletAddress: investor,
            amount: amount
        }));
        investment.raisedAmount += amount;

        emit InvestmentMade(investmentId, investor, amount);

        if (investment.raisedAmount >= investment.targetAmount) {
            investment.isCompleted = true;
            emit InvestmentCompleted(investmentId);
        }
    }

    function setInvestmentCompleted(uint256 investmentId) external onlyOwner {
        Investment storage investment = investments[investmentId];
        require(!investment.isCompleted, "Investment is already completed");
        investment.isCompleted = true;
        emit InvestmentCompleted(investmentId);
    }

    function verifyInvestment(uint256 investmentId) external onlyOwner {
        Investment storage investment = investments[investmentId];
        require(investment.isCompleted, "Investment is not completed");
        require(!investment.isVerified, "Investment is already verified");
        investment.isVerified = true;
        emit InvestmentVerified(investmentId);
    }

    function mintCreditsToInvestment(uint256 investmentId, uint256 creditAmount) external onlyOwner {
        Investment storage investment = investments[investmentId];
        require(investment.isVerified, "Investment is not verified");
        require(!investment.isCreditsClaimed, "Credits already claimed");

        investment.creditAmount = creditAmount;
        investment.isCreditsClaimed = true;

        require(carbonCreditToken.transferFrom(msg.sender, address(this), creditAmount), "Credit transfer failed");

        emit CreditsMinted(investmentId, creditAmount);
    }

    function claimCompanyCredits(uint256 investmentId, address companyWallet) external onlyOwner {
        Investment storage investment = investments[investmentId];
        require(investment.isCreditsClaimed, "Credits not yet allocated");

        uint256 companyShare = 0;
        for (uint i = 0; i < investment.participatingCompanies.length; i++) {
            if (investment.participatingCompanies[i].walletAddress == companyWallet) {
                // For simplicity, we're assuming equal distribution among participating companies
                companyShare = investment.creditAmount / investment.participatingCompanies.length;
                break;
            }
        }

        require(companyShare > 0, "Company not found or no credits to claim");
        require(carbonCreditToken.transfer(companyWallet, companyShare), "Credit transfer failed");

        emit CreditsClaimed(investmentId, companyWallet, companyShare);
    }

    function getInvestmentDetails(uint256 investmentId) external view returns (
        Company memory mainCompany,
        uint256 targetAmount,
        uint256 raisedAmount,
        uint256 creditAmount,
        bool isCompleted,
        bool isVerified,
        bool isCreditsClaimed,
        Company[] memory participatingCompanies,
        Investor[] memory investors
    ) {
        Investment storage investment = investments[investmentId];
        return (
            investment.mainCompany,
            investment.targetAmount,
            investment.raisedAmount,
            investment.creditAmount,
            investment.isCompleted,
            investment.isVerified,
            investment.isCreditsClaimed,
            investment.participatingCompanies,
            investment.investors
        );
    }
}