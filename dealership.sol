// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


contract Dealership{

    struct Car {
        string brand;
        string model;
        uint256 manYear;
        uint256 price;
    }

    struct CarsBought {
        address buyer;
        string brand;
        string model;
        uint256 manYear;
        uint256 price;
    }


    // enum Ownership{Owned, Sold,} = ow
    Car[] public carInventory;
    CarsBought[] public carOwners;
    address payable public dealershipOwner;

    constructor() {
        dealershipOwner = payable(msg.sender);
    }

    modifier onlyOwner(){
        require(msg.sender == dealershipOwner);
        _;
    }

    function addCarsToTheInventory(string memory _brand, string memory _model, uint256 _year, uint256 _price) public onlyOwner{
        Car memory newCar = Car({
            brand: _brand,
            model: _model,
            manYear: _year,
            price: _price
        });

        carInventory.push(newCar);
    }

    function getBalance() public onlyOwner view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public payable onlyOwner{
        dealershipOwner.transfer(address(this).balance);
    }

    function buyCar(uint256 _carIndex) public payable {
        require(carInventory[_carIndex].price == msg.value / 1 ether, "The amount of ether sent does not match the price of the car");

        CarsBought memory newCarBought = CarsBought({
            buyer: msg.sender,
            brand: carInventory[_carIndex].brand,
            model: carInventory[_carIndex].model,
            manYear: carInventory[_carIndex].manYear,
            price: carInventory[_carIndex].price
        });

        carOwners.push(newCarBought);

        // Swap the car to delete with the last car in the array
        carInventory[_carIndex] = carInventory[carInventory.length - 1];

        // Reduce the length of the array by one
        carInventory.pop();
    }
}