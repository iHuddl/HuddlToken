pragma solidity 0.4.24;

import "./IHuddlToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract HuddlDistribution is Ownable {
    
    using SafeMath for uint256;

    IHuddlToken token;
    
    uint256 lastReleasedQuarter;

    address public usersPool;
    address public contributorsPool;
    address public reservePool;

    uint256 public inflationRate;
    //4% == 400 (supports upto 2 decimal places) for 4.5% enter 450
    uint16 public constant INFLATION_RATE_OF_CHANGE = 400;

    uint256 public contributorDistPercent;
    uint256 public reserveDistPercent;

    uint16 public contributorROC;
    uint16 public reserveROC;

    uint8 public lastQuarter;//last quarter for which tokens were released
    
    bool public launched;
    
    //1000,000,000 (considering 18 decimal places)
    uint256 public constant MAX_SUPPLY = 1000000000000000000000000000;

    uint256[] public quarterSchedule;

    event DistributionLaunched();

    event TokensReleased(
        uint256 indexed userShare, 
        uint256 indexed reserveShare, 
        uint256 indexed contributorShare
    );

    event ReserveDistributionPercentChanged(uint256 indexed newPercent);

    event ContributorDistributionPercentChanged(uint256 indexed newPercent);

    event ReserveROCChanged(uint256 indexed newROC);

    event ContributorROCChanged(uint256 indexed newROC);

    modifier distributionLaunched() {
        require(launched, "Distribution not launched");
        _;
    }

    modifier quarterRunning() {
        require(
            lastQuarter < 72 && now >= quarterSchedule[lastQuarter],
            "Quarter not started"
        );
        _;
    }

    constructor(
        address huddlTokenAddress, 
        address _usersPool, 
        address _contributorsPool, 
        address _reservePool
    )
        public 
    {

        require(
            huddlTokenAddress != address(0), 
            "Please provide valid huddl token address"
        );
        require(
            _usersPool != address(0), 
            "Please provide valid user pool address"
        );
        require(
            _contributorsPool != address(0), 
            "Please provide valid contributors pool address"
        );
        require(
            _reservePool != address(0), 
            "Please provide valid reserve pool address"
        );
        
        usersPool = _usersPool;
        contributorsPool = _contributorsPool;
        reservePool = _reservePool;

        //considering 18 decimal places (10 * (10**18) / 100) 10%
        inflationRate = 100000000000000000;

        //considering 18 decimal places (33.333 * (10**18) /100)
        contributorDistPercent = 333330000000000000; 
        reserveDistPercent = 333330000000000000;
        
        //Supports upto 2 decimal places, for 1% enter 100, for 1.5% enter 150
        contributorROC = 100;//1%
        reserveROC = 100;//1%

        token = IHuddlToken(huddlTokenAddress);

        //Initialize 72 quarterly token release schedule for distribution. Hard-coding token release time for each quarter for precision as required
        quarterSchedule.push(1554076800); // 04/01/2019 (MM/DD/YYYY)
        quarterSchedule.push(1561939200); // 07/01/2019 (MM/DD/YYYY)
        quarterSchedule.push(1569888000); // 10/01/2019 (MM/DD/YYYY)
        quarterSchedule.push(1577836800); // 01/01/2020 (MM/DD/YYYY)
        quarterSchedule.push(1585699200); // 04/01/2020 (MM/DD/YYYY)
        quarterSchedule.push(1593561600); // 07/01/2020 (MM/DD/YYYY)
        quarterSchedule.push(1601510400); // 10/01/2020 (MM/DD/YYYY)
        quarterSchedule.push(1609459200); // 01/01/2021 (MM/DD/YYYY)
        quarterSchedule.push(1617235200); // 04/01/2021 (MM/DD/YYYY)
        quarterSchedule.push(1625097600); // 07/01/2021 (MM/DD/YYYY)
        quarterSchedule.push(1633046400); // 10/01/2021 (MM/DD/YYYY)
        quarterSchedule.push(1640995200); // 01/01/2022 (MM/DD/YYYY)
        quarterSchedule.push(1648771200); // 04/01/2022 (MM/DD/YYYY)
        quarterSchedule.push(1656633600); // 07/01/2022 (MM/DD/YYYY)
        quarterSchedule.push(1664582400); // 10/01/2022 (MM/DD/YYYY)
        quarterSchedule.push(1672531200); // 01/01/2023 (MM/DD/YYYY)
        quarterSchedule.push(1680307200); // 04/01/2023 (MM/DD/YYYY)
        quarterSchedule.push(1688169600); // 07/01/2023 (MM/DD/YYYY)
        quarterSchedule.push(1696118400); // 10/01/2023 (MM/DD/YYYY)
        quarterSchedule.push(1704067200); // 01/01/2024 (MM/DD/YYYY)
        quarterSchedule.push(1711929600); // 04/01/2024 (MM/DD/YYYY)
        quarterSchedule.push(1719792000); // 07/01/2024 (MM/DD/YYYY)
        quarterSchedule.push(1727740800); // 10/01/2024 (MM/DD/YYYY)
        quarterSchedule.push(1735689600); // 01/01/2025 (MM/DD/YYYY)
        quarterSchedule.push(1743465600); // 04/01/2025 (MM/DD/YYYY)
        quarterSchedule.push(1751328000); // 07/01/2025 (MM/DD/YYYY)
        quarterSchedule.push(1759276800); // 10/01/2025 (MM/DD/YYYY)
        quarterSchedule.push(1767225600); // 01/01/2026 (MM/DD/YYYY)
        quarterSchedule.push(1775001600); // 04/01/2026 (MM/DD/YYYY)
        quarterSchedule.push(1782864000); // 07/01/2026 (MM/DD/YYYY)
        quarterSchedule.push(1790812800); // 10/01/2026 (MM/DD/YYYY)
        quarterSchedule.push(1798761600); // 01/01/2027 (MM/DD/YYYY)
        quarterSchedule.push(1806537600); // 04/01/2027 (MM/DD/YYYY)
        quarterSchedule.push(1814400000); // 07/01/2027 (MM/DD/YYYY)
        quarterSchedule.push(1822348800); // 10/01/2027 (MM/DD/YYYY)
        quarterSchedule.push(1830297600); // 01/01/2028 (MM/DD/YYYY)
        quarterSchedule.push(1838160000); // 04/01/2028 (MM/DD/YYYY)
        quarterSchedule.push(1846022400); // 07/01/2028 (MM/DD/YYYY)
        quarterSchedule.push(1853971200); // 10/01/2028 (MM/DD/YYYY)
        quarterSchedule.push(1861920000); // 01/01/2029 (MM/DD/YYYY)
        quarterSchedule.push(1869696000); // 04/01/2029 (MM/DD/YYYY)
        quarterSchedule.push(1877558400); // 07/01/2029 (MM/DD/YYYY)
        quarterSchedule.push(1885507200); // 10/01/2029 (MM/DD/YYYY)
        quarterSchedule.push(1893456000); // 01/01/2030 (MM/DD/YYYY)
        quarterSchedule.push(1901232000); // 04/01/2030 (MM/DD/YYYY)
        quarterSchedule.push(1909094400); // 07/01/2030 (MM/DD/YYYY)
        quarterSchedule.push(1917043200); // 10/01/2030 (MM/DD/YYYY)
        quarterSchedule.push(1924992000); // 01/01/2031 (MM/DD/YYYY)
        quarterSchedule.push(1932768000); // 04/01/2031 (MM/DD/YYYY)
        quarterSchedule.push(1940630400); // 07/01/2031 (MM/DD/YYYY)
        quarterSchedule.push(1948579200); // 10/01/2031 (MM/DD/YYYY)
        quarterSchedule.push(1956528000); // 01/01/2032 (MM/DD/YYYY)
        quarterSchedule.push(1964390400); // 04/01/2032 (MM/DD/YYYY)
        quarterSchedule.push(1972252800); // 07/01/2032 (MM/DD/YYYY)
        quarterSchedule.push(1980201600); // 10/01/2032 (MM/DD/YYYY)
        quarterSchedule.push(1988150400); // 01/01/2033 (MM/DD/YYYY)
        quarterSchedule.push(1995926400); // 04/01/2033 (MM/DD/YYYY)
        quarterSchedule.push(2003788800); // 07/01/2033 (MM/DD/YYYY)
        quarterSchedule.push(2011737600); // 10/01/2033 (MM/DD/YYYY)
        quarterSchedule.push(2019686400); // 01/01/2034 (MM/DD/YYYY)
        quarterSchedule.push(2027462400); // 04/01/2034 (MM/DD/YYYY)
        quarterSchedule.push(2035324800); // 07/01/2034 (MM/DD/YYYY)
        quarterSchedule.push(2043273600); // 10/01/2034 (MM/DD/YYYY)
        quarterSchedule.push(2051222400); // 01/01/2035 (MM/DD/YYYY)
        quarterSchedule.push(2058998400); // 04/01/2035 (MM/DD/YYYY)
        quarterSchedule.push(2066860800); // 07/01/2035 (MM/DD/YYYY)
        quarterSchedule.push(2074809600); // 10/01/2035 (MM/DD/YYYY)
        quarterSchedule.push(2082758400); // 01/01/2036 (MM/DD/YYYY)
        quarterSchedule.push(2090620800); // 04/01/2036 (MM/DD/YYYY)
        quarterSchedule.push(2098483200); // 07/01/2036 (MM/DD/YYYY)
        quarterSchedule.push(2106432000); // 10/01/2036 (MM/DD/YYYY)
        quarterSchedule.push(2114380800); // 01/01/2037 (MM/DD/YYYY)
    }

    /** 
    * @dev When the distribution will start the initial set of tokens will be distributed amongst users, reserve and contributors as per specs
    * Before calling this method the owner must transfer all the initial supply tokens to this distribution contract
    */
    function launchDistribution() external onlyOwner {

        require(!launched, "Distribution already launched");

        launched = true;

        (
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        ) = getDistributionShares(token.totalSupply());

        token.transfer(usersPool, userShare);
        token.transfer(contributorsPool, contributorShare);
        token.transfer(reservePool, reserveShare);
        adjustDistributionPercentage();
        emit DistributionLaunched();
    } 

    /** 
    * @dev This method allows owner of the contract to release tokens for the quarter.
    * So suppose current quarter is 5 and previously released quarter is 3 then owner will have to send 2 transaction to release all tokens upto this quarter.
    * First transaction will release tokens for quarter 4 and Second transaction will release tokens for quarter 5. This is done to reduce complexity.
    */
    function releaseTokens()
        external 
        onlyOwner 
        distributionLaunched
        quarterRunning//1. Check if quarter date has been reached
        returns(bool)
    {   
        
        //2. Increment quarter. Overflow will never happen as maximum quarters can be 72
        lastQuarter = lastQuarter + 1;

        //3. Calculate amount of tokens to be released
        uint256 amount = getTokensToMint();

        //4. Check if amount is greater than 0
        require(amount>0, "No tokens to be released");

        //5. Calculate share of user, reserve and contributor
        (
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        ) = getDistributionShares(amount);

        //6. Change inflation rate, for next release/quarter
        adjustInflationRate();

        //7. Change distribution percentage for next quarter
        adjustDistributionPercentage();

        //8. Mint and transfer tokens to respective pools
        token.mint(usersPool, userShare);
        token.mint(contributorsPool, contributorShare);
        token.mint(reservePool, reserveShare);

        //9. Emit event
        emit TokensReleased(
            userShare, 
            reserveShare, 
            contributorShare
        );
    }
   
    /** 
    * @dev This method will return the release time for upcoming quarter
    */
    function nextReleaseTime() external view returns(uint256 time) {
        time = quarterSchedule[lastQuarter];
    }

    /** 
    * @dev This method will returns whether the next quarter's token can be released now or not
    */
    function canRelease() external view returns(bool release) {
        release = now >= quarterSchedule[lastQuarter];
    }

    /** 
    * @dev Returns current distribution percentage for user pool
    */
    function userDistributionPercent() external view returns(uint256) {
        uint256 totalPercent = 1000000000000000000;
        return(
            totalPercent.sub(contributorDistPercent.add(reserveDistPercent))
        );
    }

    /** 
    * @dev Allows owner to change reserve distribution percentage for next quarter
    * Consequent calculations will be done on this basis
    * @param newPercent New percentage. Ex for 45.33% pass (45.33 * (10**18) /100) = 453330000000000000
    */
    function changeReserveDistributionPercent(
        uint256 newPercent
    )
        external 
        onlyOwner
    {
        reserveDistPercent = newPercent;
        emit ReserveDistributionPercentChanged(newPercent);
    }

    /** 
    * @dev Allows owner to change contributor distribution percentage for next quarter
    * Consequent calculations will be done on this basis
    * @param newPercent New percentage. Ex for 45.33% pass (45.33 * (10**18) /100) = 453330000000000000
    */
    function changeContributorDistributionPercent(
        uint256 newPercent
    )
        external 
        onlyOwner
    {
        contributorDistPercent = newPercent;
        emit ContributorDistributionPercentChanged(newPercent);
    }

    /** 
    * @dev Allows owner to change ROC for reserve pool
    * @dev newROC New ROC. Ex- for 1% enter 100, for 1.5% enter 150
    */
    function changeReserveROC(uint16 newROC) external onlyOwner {
        reserveROC = newROC;
        emit ReserveROCChanged(newROC);
    }

    /** 
    * @dev Allows owner to change ROC for contributor pool
    * @dev newROC New ROC. Ex- for 1% enter 100, for 1.5% enter 150
    */
    function changeContributorROC(uint16 newROC) external onlyOwner {
        contributorROC = newROC;
        emit ContributorROCChanged(newROC);
    }

    /** 
    * @dev This method returns the share of user, reserve and contributors for given token amount as per current distribution
    * @param amount The amount of tokens for which the shares have to be calculated
    */
    function getDistributionShares(
        uint256 amount
    )
        public 
        view 
        returns(
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        )
    {
        contributorShare = contributorDistPercent.mul(
            amount.div(10**uint256(token.decimals()))
        );

        reserveShare = reserveDistPercent.mul(
            amount.div(10**uint256(token.decimals()))
        );

        userShare = amount.sub(
            contributorShare.add(reserveShare)
        );

        assert(
            contributorShare.add(reserveShare).add(userShare) == amount
        );
    }

    
    /** 
    * @dev Returns amount of tokens to be minted in next release(quarter)
    */    
    function getTokensToMint() public view returns(uint256 amount) {
        
        if (MAX_SUPPLY == token.totalSupply()){
            return 0;
        }

        //dividing by decimal places(18) since that is already multiplied in inflation rate
        amount = token.totalSupply().div(
            10 ** uint256(token.decimals())
        ).mul(inflationRate);

        if (amount.add(token.totalSupply()) > MAX_SUPPLY){
            amount = MAX_SUPPLY.sub(token.totalSupply());
        }
    }

    function adjustDistributionPercentage() private {
        contributorDistPercent = contributorDistPercent.sub(
            contributorDistPercent.mul(contributorROC).div(10000)
        );

        reserveDistPercent = reserveDistPercent.sub(
            reserveDistPercent.mul(reserveROC).div(10000)
        );
    }

    function adjustInflationRate() private {
        inflationRate = inflationRate.sub(
            inflationRate.mul(INFLATION_RATE_OF_CHANGE).div(10000)
        );
    }

    
}