//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract RideBooking {
    address public immutable owner; // Contract owner
    uint256 public rideFeePercentage = 2; // Platform fee (2% of the fare)

    struct Ride {
        address payable rider;
        address payable driver;
        uint256 fare;
        bool isCompleted;
        bool isPaid;
    }

    mapping(uint256 => Ride) public rides;
    uint256 public rideCount;

    event RideBooked(uint256 indexed rideId, address indexed rider, address indexed driver, uint256 fare);
    event RideCompleted(uint256 indexed rideId);
    event PaymentReleased(uint256 indexed rideId, address indexed driver, uint256 amount);
    event RideFeePercentageChanged(uint256 oldFee, uint256 newFee);

    constructor() {
        owner = msg.sender; // Set the owner of the contract
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyDriver(uint256 _rideId) {
        require(msg.sender == rides[_rideId].driver, "Not authorized driver");
        _;
    }

    modifier onlyRider(uint256 _rideId) {
        require(msg.sender == rides[_rideId].rider, "Not authorized rider");
        _;
    }

    // Function to book a ride
    function bookRide(address payable _driver) external payable {
        require(msg.value > 0, "Fare must be greater than 0");
        require(_driver != address(0), "Invalid driver address");

        rideCount++;
        rides[rideCount] = Ride({
            rider: payable(msg.sender),
            driver: _driver,
            fare: msg.value,
            isCompleted: false,
            isPaid: false
        });

        emit RideBooked(rideCount, msg.sender, _driver, msg.value);
    }

    // Function to complete a ride (called by the driver)
    function completeRide(uint256 _rideId) external onlyDriver(_rideId) {
        Ride storage ride = rides[_rideId];
        require(!ride.isCompleted, "Ride already completed");

        ride.isCompleted = true;
        emit RideCompleted(_rideId);
    }

    // Function to release payment after ride completion (called by rider)
    function releasePayment(uint256 _rideId) external onlyRider(_rideId) {
        Ride storage ride = rides[_rideId];
        require(ride.isCompleted, "Ride not completed");
        require(!ride.isPaid, "Ride already paid");

        uint256 platformFee = (ride.fare * rideFeePercentage) / 100;
        uint256 driverAmount = ride.fare - platformFee;

        // Transfer the amounts safely
        (bool driverPaid,) = ride.driver.call{value: driverAmount}("");
        require(driverPaid, "Driver payment failed");

        (bool feePaid,) = payable(owner).call{value: platformFee}("");
        require(feePaid, "Platform fee payment failed");

        ride.isPaid = true;
        emit PaymentReleased(_rideId, ride.driver, driverAmount);
    }

    // Function to adjust the platform fee percentage (only the contract owner can call)
    function setRideFeePercentage(uint256 _newFee) external onlyOwner {
        require(_newFee <= 100, "Fee cannot be more than 100%");
        uint256 oldFee = rideFeePercentage;
        if (oldFee != _newFee) {
            rideFeePercentage = _newFee;
            emit RideFeePercentageChanged(oldFee, _newFee);
        }
    }

    // Function to retrieve the current ride details
    function getRideDetails(uint256 _rideId) external view returns (Ride memory) {
        return rides[_rideId];
    }
}
