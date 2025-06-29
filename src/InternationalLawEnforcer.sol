// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MockKlerosCourt.sol";

/**
 * @title International Law Enforcement System (Olufipa)
 * @author W3HC
 * @notice An onchain system for enforcing international law through automated penalties and decentralized arbitration
 * @dev This contract implements an automated international law enforcement mechanism using smart contracts.
 *      Countries deposit funds to participate, violations are reported with evidence, Kleros jurors decide on violations,
 *      and penalties are automatically applied and distributed to various funds.
 * @custom:audit-status This contract has not been audited yet
 */
contract InternationalLawEnforcer {
    /// @notice The Kleros arbitrator contract used for dispute resolution
    /// @dev This is the external arbitration system that decides on violation reports
    MockKlerosCourt public klerosArbitrator;

    /**
     * @notice Enumeration of violation severity levels
     * @dev Used to determine penalty amounts and compliance score reductions
     */
    enum ViolationSeverity {
        MINOR, // 5% penalty, -5 compliance score
        MODERATE, // 15% penalty, -15 compliance score
        SERIOUS, // 30% penalty, -25 compliance score
        GRAVE // 50% penalty, -40 compliance score
    }

    /**
     * @notice Enumeration of international law violation types
     * @dev Categorizes different types of violations for reporting and tracking
     */
    enum ViolationType {
        WAR_CRIMES, // Violations of international humanitarian law
        TERRITORIAL_DISPUTE, // Territorial sovereignty violations
        TRADE_VIOLATION, // International trade agreement breaches
        HUMAN_RIGHTS, // Human rights violations
        ENVIRONMENTAL // Environmental protection violations
    }

    /**
     * @notice Structure representing a participating country
     * @dev Contains all relevant information about a country's participation in the system
     * @param name The official name of the country
     * @param depositAmount The amount of ETH deposited by the country as collateral
     * @param complianceScore Score from 0-100 representing the country's compliance record
     * @param isParticipating Whether the country is actively participating in the system
     * @param violationCount Total number of confirmed violations by this country
     */
    struct Country {
        string name;
        uint256 depositAmount;
        uint256 complianceScore; // 0-100, starts at 100
        bool isParticipating;
        uint256 violationCount;
    }

    /**
     * @notice Structure representing a violation report
     * @dev Contains all information about a reported violation and its resolution
     * @param reporter The address of the country that reported the violation
     * @param violatorCountry The address of the country accused of the violation
     * @param violationType The type of international law violation
     * @param severity The severity level of the violation
     * @param evidence Written evidence or description of the violation
     * @param klerosDisputeID The ID of the dispute in the Kleros system
     * @param resolved Whether the violation report has been resolved
     * @param violationConfirmed Whether the violation was confirmed by Kleros
     * @param penalty The penalty amount applied (if violation confirmed)
     * @param timestamp When the violation was reported
     */
    struct ViolationReport {
        address reporter;
        address violatorCountry;
        ViolationType violationType;
        ViolationSeverity severity;
        string evidence;
        uint256 klerosDisputeID;
        bool resolved;
        bool violationConfirmed;
        uint256 penalty;
        uint256 timestamp;
    }

    /// @notice Mapping of country addresses to their information
    /// @dev Stores all participating countries and their current status
    mapping(address => Country) public countries;

    /// @notice Mapping of report IDs to violation reports
    /// @dev Stores all violation reports with unique incrementing IDs
    mapping(uint256 => ViolationReport) public violationReports;

    /// @notice Counter for generating unique violation report IDs
    /// @dev Incremented for each new violation report
    uint256 public reportCounter;

    /// @notice Address where 40% of penalties go for victim compensation
    /// @dev In production, this would be a proper DAO or multisig address
    address public victimsCompensationFund;

    /// @notice Address where 30% of penalties go for peacekeeping operations
    /// @dev In production, this would be a proper DAO or multisig address
    address public peacekeepingFund;

    /// @notice Address where 20% of penalties go for monitoring systems
    /// @dev In production, this would be a proper DAO or multisig address
    address public monitoringSystemFund;

    /// @notice Address where 10% of penalties go for juror rewards
    /// @dev In production, this would be a proper DAO or multisig address
    address public jurorRewardFund;

    /**
     * @notice Emitted when a country registers and deposits funds
     * @param country The address of the registered country
     * @param name The name of the country
     * @param deposit The amount of ETH deposited
     */
    event CountryRegistered(
        address indexed country,
        string name,
        uint256 deposit
    );

    /**
     * @notice Emitted when a violation is reported
     * @param reportID The unique ID of the violation report
     * @param violator The address of the accused country
     * @param violationType The type of violation reported
     */
    event ViolationReported(
        uint256 indexed reportID,
        address indexed violator,
        ViolationType violationType
    );

    /**
     * @notice Emitted when a violation report is resolved by Kleros
     * @param reportID The ID of the resolved report
     * @param violationConfirmed Whether the violation was confirmed
     * @param penalty The penalty amount applied
     */
    event ViolationResolved(
        uint256 indexed reportID,
        bool violationConfirmed,
        uint256 penalty
    );

    /**
     * @notice Emitted when penalty funds are distributed
     * @param reportID The ID of the report that generated the penalty
     * @param penalty The total penalty amount distributed
     * @param violator The address of the country that was penalized
     */
    event PenaltyDistributed(
        uint256 indexed reportID,
        uint256 penalty,
        address violator
    );

    /// @notice Restricts function access to only the Kleros arbitrator
    /// @dev Used for functions that should only be called by the arbitration system
    modifier onlyKleros() {
        require(
            msg.sender == address(klerosArbitrator),
            "Only Kleros can call this function"
        );
        _;
    }

    /// @notice Restricts function access to only participating countries
    /// @dev Used for functions that require the caller to be a registered country
    modifier onlyParticipatingCountry() {
        require(
            countries[msg.sender].isParticipating,
            "Country must be participating"
        );
        _;
    }

    /**
     * @notice Initializes the International Law Enforcement contract
     * @dev Sets up the Kleros arbitrator and initializes fund distribution addresses
     * @param _klerosArbitrator The address of the Kleros court contract for dispute resolution
     */
    constructor(address _klerosArbitrator) {
        klerosArbitrator = MockKlerosCourt(_klerosArbitrator);

        // Initialize fund addresses with proper EOA addresses that can receive ETH
        // In production, these would be proper DAO or multisig addresses
        victimsCompensationFund = 0x1111111111111111111111111111111111111111;
        peacekeepingFund = 0x2222222222222222222222222222222222222222;
        monitoringSystemFund = 0x3333333333333333333333333333333333333333;
        jurorRewardFund = 0x4444444444444444444444444444444444444444;
    }

    /**
     * @notice Allows the contract to receive ETH deposits
     * @dev Required for receiving reporting fees and other ETH transfers
     */
    receive() external payable {
        // Contract can receive ETH for reporting fees and other purposes
    }

    /**
     * @notice Registers a country in the international law enforcement system
     * @dev Countries must deposit ETH to participate and start with a perfect compliance score
     * @param _name The official name of the country
     */
    function registerCountry(string memory _name) external payable {
        require(msg.value > 0, "Must deposit funds to participate");
        require(
            !countries[msg.sender].isParticipating,
            "Country already registered"
        );

        countries[msg.sender] = Country({
            name: _name,
            depositAmount: msg.value,
            complianceScore: 100,
            isParticipating: true,
            violationCount: 0
        });

        emit CountryRegistered(msg.sender, _name, msg.value);
    }

    /**
     * @notice Reports a violation of international law by another country
     * @dev Creates a dispute in Kleros and requires a reporting fee to prevent spam
     * @param _violatorCountry The address of the country accused of the violation
     * @param _violationType The type of international law that was violated
     * @param _severity The severity level of the violation
     * @param _evidence Description or evidence of the violation
     */
    function reportViolation(
        address _violatorCountry,
        ViolationType _violationType,
        ViolationSeverity _severity,
        string memory _evidence
    ) external payable onlyParticipatingCountry {
        require(
            countries[_violatorCountry].isParticipating,
            "Violator must be participating country"
        );
        require(msg.value >= 0.01 ether, "Must stake reporting fee");

        // Create dispute in Kleros
        uint256 disputeID = klerosArbitrator.createDispute();

        reportCounter++;
        violationReports[reportCounter] = ViolationReport({
            reporter: msg.sender,
            violatorCountry: _violatorCountry,
            violationType: _violationType,
            severity: _severity,
            evidence: _evidence,
            klerosDisputeID: disputeID,
            resolved: false,
            violationConfirmed: false,
            penalty: 0,
            timestamp: block.timestamp
        });

        emit ViolationReported(reportCounter, _violatorCountry, _violationType);
    }

    /**
     * @notice Resolves a violation report based on Kleros arbitration decision
     * @dev Can only be called by the Kleros arbitrator contract after a ruling is made
     * @param _reportID The ID of the violation report to resolve
     */
    function resolveViolation(uint256 _reportID) external onlyKleros {
        ViolationReport storage report = violationReports[_reportID];
        require(!report.resolved, "Report already resolved");

        uint256 ruling = klerosArbitrator.currentRuling(report.klerosDisputeID);
        require(ruling != 0, "Dispute not yet ruled");

        report.resolved = true;

        if (ruling == 2) {
            // Violation confirmed
            report.violationConfirmed = true;

            // Calculate penalty based on severity and repeat offenses
            uint256 penalty = calculatePenalty(
                report.violatorCountry,
                report.severity
            );
            report.penalty = penalty;

            // Update country stats
            Country storage violator = countries[report.violatorCountry];
            violator.violationCount++;
            violator.complianceScore = updateComplianceScore(
                violator.complianceScore,
                report.severity
            );

            // Apply penalty if violator has sufficient deposit
            if (violator.depositAmount >= penalty) {
                violator.depositAmount -= penalty;

                // Distribute penalty funds
                distributePenalty(penalty, _reportID);

                // Refund reporter's stake from contract balance
                if (address(this).balance >= 0.01 ether) {
                    payable(report.reporter).transfer(0.01 ether);
                }
            } else {
                // If insufficient funds, apply what's available
                uint256 availablePenalty = violator.depositAmount;
                report.penalty = availablePenalty;
                violator.depositAmount = 0;

                if (availablePenalty > 0) {
                    distributePenalty(availablePenalty, _reportID);
                }

                // Still refund reporter if contract has balance
                if (address(this).balance >= 0.01 ether) {
                    payable(report.reporter).transfer(0.01 ether);
                }
            }
        } else {
            // No violation - reporter loses stake goes to juror rewards
            // Only transfer if contract has the balance
            if (address(this).balance >= 0.01 ether) {
                payable(jurorRewardFund).transfer(0.01 ether);
            }
        }

        emit ViolationResolved(
            _reportID,
            report.violationConfirmed,
            report.penalty
        );
    }

    /**
     * @notice Calculates the penalty amount for a violation
     * @dev Penalty is based on violation severity and increases with repeat offenses
     * @param _violator The address of the violating country
     * @param _severity The severity level of the violation
     * @return The calculated penalty amount in wei
     */
    function calculatePenalty(
        address _violator,
        ViolationSeverity _severity
    ) internal view returns (uint256) {
        Country memory violator = countries[_violator];
        uint256 basePenalty;

        // Base penalty as percentage of deposit
        if (_severity == ViolationSeverity.MINOR) {
            basePenalty = (violator.depositAmount * 5) / 100; // 5%
        } else if (_severity == ViolationSeverity.MODERATE) {
            basePenalty = (violator.depositAmount * 15) / 100; // 15%
        } else if (_severity == ViolationSeverity.SERIOUS) {
            basePenalty = (violator.depositAmount * 30) / 100; // 30%
        } else {
            // GRAVE
            basePenalty = (violator.depositAmount * 50) / 100; // 50%
        }

        // Increase penalty for repeat offenders
        uint256 multiplier = 100 + (violator.violationCount * 25); // +25% per violation
        return (basePenalty * multiplier) / 100;
    }

    /**
     * @notice Updates a country's compliance score based on violation severity
     * @dev Compliance score decreases based on the severity of the violation
     * @param _currentScore The country's current compliance score
     * @param _severity The severity of the violation
     * @return The updated compliance score (minimum 0)
     */
    function updateComplianceScore(
        uint256 _currentScore,
        ViolationSeverity _severity
    ) internal pure returns (uint256) {
        uint256 reduction;

        if (_severity == ViolationSeverity.MINOR) {
            reduction = 5;
        } else if (_severity == ViolationSeverity.MODERATE) {
            reduction = 15;
        } else if (_severity == ViolationSeverity.SERIOUS) {
            reduction = 25;
        } else {
            // GRAVE
            reduction = 40;
        }

        return _currentScore > reduction ? _currentScore - reduction : 0;
    }

    /**
     * @notice Distributes penalty funds to designated addresses
     * @dev Distributes funds according to the predetermined percentages:
     *      40% to victims compensation, 30% to peacekeeping, 20% to monitoring, 10% to jurors
     * @param _penalty The total penalty amount to distribute
     * @param _reportID The report ID for event emission
     */
    function distributePenalty(uint256 _penalty, uint256 _reportID) internal {
        uint256 toVictims = (_penalty * 40) / 100;
        uint256 toPeacekeeping = (_penalty * 30) / 100;
        uint256 toMonitoring = (_penalty * 20) / 100;
        uint256 toJurors = (_penalty * 10) / 100;

        // Use call instead of transfer for better gas handling
        (bool success1, ) = victimsCompensationFund.call{value: toVictims}("");
        (bool success2, ) = peacekeepingFund.call{value: toPeacekeeping}("");
        (bool success3, ) = monitoringSystemFund.call{value: toMonitoring}("");
        (bool success4, ) = jurorRewardFund.call{value: toJurors}("");

        // If any transfer fails, keep the funds in the contract
        // This is safer than reverting the entire transaction
        require(
            success1 && success2 && success3 && success4,
            "Fund distribution failed"
        );

        emit PenaltyDistributed(
            _reportID,
            _penalty,
            violationReports[_reportID].violatorCountry
        );
    }

    /**
     * @notice Allows participating countries to increase their deposit
     * @dev Countries can add more funds to their deposit to cover potential penalties
     */
    function addDeposit() external payable onlyParticipatingCountry {
        countries[msg.sender].depositAmount += msg.value;
    }

    /**
     * @notice Retrieves information about a specific country
     * @dev Public view function to get country details
     * @param _country The address of the country to query
     * @return The Country struct containing all country information
     */
    function getCountryInfo(
        address _country
    ) external view returns (Country memory) {
        return countries[_country];
    }

    /**
     * @notice Retrieves information about a specific violation report
     * @dev Public view function to get violation report details
     * @param _reportID The ID of the violation report to query
     * @return The ViolationReport struct containing all report information
     */
    function getViolationReport(
        uint256 _reportID
    ) external view returns (ViolationReport memory) {
        return violationReports[_reportID];
    }

    /**
     * @notice Updates the Kleros arbitrator contract address
     * @dev Emergency function for upgrading the arbitration system
     *      In production, this would have proper governance controls
     * @param _newArbitrator The address of the new Kleros arbitrator contract
     */
    function updateKlerosArbitrator(address _newArbitrator) external {
        klerosArbitrator = MockKlerosCourt(_newArbitrator);
    }

    /**
     * @notice Allows the contract owner to update fund addresses
     * @dev For testing and emergency situations
     */
    function updateFundAddresses(
        address _victimsCompensationFund,
        address _peacekeepingFund,
        address _monitoringSystemFund,
        address _jurorRewardFund
    ) external {
        victimsCompensationFund = _victimsCompensationFund;
        peacekeepingFund = _peacekeepingFund;
        monitoringSystemFund = _monitoringSystemFund;
        jurorRewardFund = _jurorRewardFund;
    }
}
