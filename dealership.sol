// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**@title A Car Dealership Contract
 * @author Ciphadus
 * @notice This contract is for creating a sample car dealership.
 * @dev This implements various concepts to test my own skills.
 */

contract Dealership{
    /* Type declarations */
    struct Car {
        string brand;
        string model;
        uint256 manYear;
        uint256 price;
    }

    struct CarsBought {
        address owner;
        string brand;
        string model;
        uint256 manYear;
        uint256 price;
    }

    struct waitingApproval {
        address owner;
        string brand;
        string model;
        uint256 manYear;
        uint256 price; 
    }


    /* State variables */
    Car[] public newCarsForSale;
    Car[] public usedCarsForSale;
    CarsBought[] public carOwners;
    waitingApproval[] public waiting;
    address payable public dealershipOwner;
    bool internal locked;
    mapping(address => uint256) public lastCallTimestamp;


    modifier onlyOwner(){
        require(msg.sender == dealershipOwner);
        _;
    }

    modifier noReentrancy(){        // Honestly, this is super redundant. But hey, security.
        require(!locked, "NOPE NOPE");
        locked = true;
        _;
        locked = false;
    }

    /* Functions */
    constructor() {
        dealershipOwner = payable(msg.sender);
    }


    /**
    @dev The owner can add new cars to the inventory. 
     */
    function addNewCarsToTheInventory(string memory _brand, string memory _model, uint256 _year, uint256 _price) external onlyOwner{
        Car memory newCar = Car({
            brand: _brand,
            model: _model,
            manYear: _year,
            price: _price
        });

        newCarsForSale.push(newCar);
    }
    /**
    @dev The owner can add used cars to the inventory. 
     */
    function addUsedCarsToTheInventory(string memory _brand, string memory _model, uint256 _year, uint256 _price) external onlyOwner{
        Car memory usedCar = Car({
            brand: _brand,
            model: _model,
            manYear: _year,
            price: _price
        });

        usedCarsForSale.push(usedCar);
    }


    /**
    @dev The owner can call this function by passing either 'used' or 'new' and then index of the car
    in the respective array to remove a bad entry from the array.
    */
    function removeCarByIndex(string memory _arrayType, uint256 _index) external onlyOwner {
        if (keccak256(bytes(_arrayType)) == keccak256(bytes("new"))) {
            require(_index < newCarsForSale.length, "Invalid index");
            newCarsForSale[_index] = newCarsForSale[newCarsForSale.length - 1];
            newCarsForSale.pop();
        } else if (keccak256(bytes(_arrayType)) == keccak256(bytes("used"))) {
            require(_index < usedCarsForSale.length, "Invalid index");
            usedCarsForSale[_index] = usedCarsForSale[usedCarsForSale.length - 1];
            usedCarsForSale.pop();
        }

    }

    function getBalance() external onlyOwner view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() external payable onlyOwner{
        dealershipOwner.transfer(address(this).balance);
    }

    /**
    @dev Buyer can purchase a new car and their info will be added to carOwners array. Removes the car
    from the newCarsForSale array.
     */
    function buyNewCar(uint256 _carIndex) external payable noReentrancy {
        require(newCarsForSale[_carIndex].price == msg.value / 1 ether, "The amount of ether sent does not match the price of the car");
        CarsBought memory newCarBought = CarsBought({
            owner: msg.sender,
            brand: newCarsForSale[_carIndex].brand,
            model: newCarsForSale[_carIndex].model,
            manYear: newCarsForSale[_carIndex].manYear,
            price: newCarsForSale[_carIndex].price
        });
        carOwners.push(newCarBought);
        // Swap the car to delete with the last car in the array
        newCarsForSale[_carIndex] = newCarsForSale[newCarsForSale.length - 1];
        // Reduce the length of the array by one
        newCarsForSale.pop();
        
    }
    /**
    @dev Buyer can purchase a used car and their info will be added to carOwners array. Removes the car
    from usedCarsForSale array.
     */
    function buyUsedCar(uint256 _carIndex) external payable noReentrancy{
        require(usedCarsForSale[_carIndex].price == msg.value / 1 ether, "The amount of ether sent does not match the price of the car");
        CarsBought memory usedCarBought = CarsBought({
            owner: msg.sender,
            brand: usedCarsForSale[_carIndex].brand,
            model: usedCarsForSale[_carIndex].model,
            manYear: usedCarsForSale[_carIndex].manYear,
            price: usedCarsForSale[_carIndex].price
        });
        carOwners.push(usedCarBought);
        // Swap the car to delete with the last car in the array
        usedCarsForSale[_carIndex] = usedCarsForSale[usedCarsForSale.length - 1];
        // Reduce the length of the array by one
        usedCarsForSale.pop();
        
    }



    /**
    @dev The owner of a car puts their car on a waiting list so that its either approved or
    disapproved by the car dealership owner. Basically, the car dealership owners buys the car back.
    If the owner finds the price feasible, they can approve it. If not, they can disapprove it.
    Of course, there can be multiple reasons to approve or disapprove like money, car desirability etc.
    The car is added to the waiting array, provided, the car owner itself is putting it up for sale.
    To avoid spam, a user can only send this request once.
     */
    function putCarForSaleWaitingApproval(uint256 _index, uint256 _price) external noReentrancy {
        require(msg.sender == carOwners[_index].owner, "You're not the owner of this car.");
        require(block.timestamp >= lastCallTimestamp[msg.sender] + (7 * 1 days), "You can only call this function once every 7 days.");

        waitingApproval memory approvalData = waitingApproval({
            owner: carOwners[_index].owner,
            brand: carOwners[_index].brand,
            model: carOwners[_index].model,
            manYear: carOwners[_index].manYear,
            price: _price
        });
        waiting.push(approvalData);

        lastCallTimestamp[msg.sender] = block.timestamp;
    }
    /**
    @dev The owner can approve the purchase of an owner's car that had been put up for sale by them.
    We first send the amount that was approved and then we add the car to our usedCars array.
    We also remove the car from the waiting array.
    */
   function approvePurchaseOfCarFromOwner(uint256 _index) external payable onlyOwner {
        uint256 amountInEther = waiting[_index].price * 1 ether;
        payable(waiting[_index].owner).transfer(amountInEther);

        Car memory usedCarMem = Car({
            brand: waiting[_index].brand,
            model: waiting[_index].model,
            manYear: waiting[_index].manYear,
            price: waiting[_index].price
        });

        usedCarsForSale.push(usedCarMem);
        waiting[_index] = waiting[waiting.length - 1];
        waiting.pop();
        carOwners[_index] = carOwners[carOwners.length - 1];
        carOwners.pop();
    }


    /**
    @dev The owner can disapprove the purchase of an owner's car that had been put up for sale by them.
    We just simply remove the car from the waiting list. On the front-end, it should send a message to the owner using some interface
    idk.
     */
    function disapprovePurchaseOfCarFromOwner(uint256 _index) external onlyOwner() {
        waiting[_index] = waiting[waiting.length - 1];
        waiting.pop();
    }

}