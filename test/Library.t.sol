// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/Library.sol";

contract LibraryTest is Test {  //this test contract inherits fro Test, which is part of forge-std. It gives one access to cheat codes like vm.prank, vm.expectRevert, assertEq, etc.
    Library libraryContract;
    address admin = address(0x1); // define test addresses
    address user1 = address(0x2);
    address user2 = address(0x3);
    address nonAdmin = address(0x4);

    event BookAdded(uint256 indexed bookId, string author,string title, uint256 totalCopies);
    event BookBorrowed(address indexed user, uint256 indexed bookId, uint256 borrowTime);
    event BookReturned(address indexed user, uint256 indexed bookId, uint256 returnTime);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    //setup
    function setUp() public { //runs before each test. deploys the Library contract with admin as the deployer using vm.prank
        vm.prank(admin);
        libraryContract = new Library();
    }

    //Test coverage
    function testDeployment() public view { //verifies admin is set correctly/ensures the contract's admin is the deployer of the contract
        assertEq(libraryContract.admin(), admin, "Admin should be set correctly");
    }

    function testAddBook() public {
        vm.prank(admin);  //mocks admin as sender
        vm.expectEmit(true, false, false, true); //expects the BookAdded event
        emit BookAdded(1, "J.K. Rowling", "Harry Potter", 5); //calls addBook
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 5);
        (string memory title, string memory author, uint256 totalCopies, uint256 availableCopies) = libraryContract.getBookDetails(1);
        assertEq(title, "Harry Potter", "Title should match");
        assertEq(author, "J.K. Rowling", "Author should match");
        assertEq(totalCopies, 5, "Total copies should match");
        assertEq(availableCopies, 5, "Available copies should match");
    }

    function testAddInvalidInput() public {
        vm.prank(admin);
        vm.expectRevert(Library.InvalidInput.selector);
        libraryContract.addBook("", "J.K.Rowling", 5);

        vm.prank(admin);
        vm.expectRevert(Library.InvalidInput.selector);
        libraryContract.addBook("Harry Potter", "", 5);

        vm.prank(admin);
        vm. expectRevert(Library.InvalidInput.selector);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 0);
    }

    function testAddBookNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(Library.OnlyAdmin.selector);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 5);
    }   
    
    function testBorrowBook() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 2);

        vm.prank(user1);
        vm.expectEmit(true, true, false, false); //expects the BookBorrowed event
        emit BookBorrowed(user1, 1, block.timestamp); //calls borrowBook
        libraryContract.borrowBook(1);

        (,,, uint256 availableCopies) = libraryContract.getBookDetails(1);
            
        assertEq(availableCopies, 1, "Available copies should decrease to 1");
        (uint256 bookid, uint256 borrowTime, bool active) = libraryContract.getUserBorrow(user1);
        
        assertEq(bookid, 1, "BOok ID should be 1");
        assertEq(borrowTime, block.timestamp, "Borrow time should match");
        assertTrue(active, "Borrow should be active");
    }

    function testBookNotFound() public {
        vm.prank(user1);
        vm.expectRevert(Library.BookNotFound.selector);
        libraryContract.borrowBook(1);
        }
    
    function testBorrowBookNoCopiesAvailable() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 1);
        vm.prank(user1);
        libraryContract.borrowBook(1);
        vm.prank(user2);
        vm.expectRevert(Library.NoCopiesAvailable.selector);
        libraryContract.borrowBook(1);
    }

    function testBorrowBookAlreadyBorrowed() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 2);
        vm.prank(user1);
        libraryContract.borrowBook(1);
        vm.prank(user1);
        vm.expectRevert(Library.BookAlreadyBorrowed.selector);
        libraryContract.borrowBook(1);   
    }

    function testReturnBook() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 2);
        vm.prank(user1);
        libraryContract.borrowBook(1);
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit BookReturned(user1, 1, block.timestamp);
        libraryContract.returnBook();
          (,,, uint256 availableCopies) = libraryContract.getBookDetails(1);
        assertEq(availableCopies, 2, "Available copies should increase to 2");
        (uint256 bookId, uint256 borrowTime, bool active) = libraryContract.getUserBorrow(user1);
        assertEq(bookId, 0, "Book ID should be reset");
        assertEq(borrowTime, 0, "Borrow time should be reset");
        assertFalse(active, "Borrow should be inactive");
    }

    function testReturnBookNoActiveBorrow() public {
        vm.prank(user1);
        vm.expectRevert(Library.NoActiveBorrow.selector);
        libraryContract.returnBook();
    }

    function testTransferAdmin() public {
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit AdminChanged(admin, nonAdmin);
        libraryContract.transferAdmin(nonAdmin);
        assertEq(libraryContract.admin(), nonAdmin, "Admin should be updated");
    }

    function testTransferAdminInvalidInput() public {
        vm.prank(admin);
        vm.expectRevert(Library.InvalidInput.selector);
        libraryContract.transferAdmin(address(0));
    }

    function testTransferNonAdmin() public{
        vm.prank(user1);
        vm.expectRevert(Library.OnlyAdmin.selector);
        libraryContract.transferAdmin(user1);
    }

    function testGetBookDetails() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 5);
        (string memory title, string memory author, uint256 totalCopies, uint256 availableCopies) = libraryContract.getBookDetails(1);
        assertEq(title, "Harry Potter", "Title should match");
        assertEq(author, "J.K. Rowling", "Author should match");
        assertEq(totalCopies, 5, "Total copies should be 5");
        assertEq(availableCopies, 5, "Available copies should be 5");
    }

    function testGetUserBorrow() public {
        vm.prank(admin);
        libraryContract.addBook("Harry Potter", "J.K. Rowling", 1);
        vm.prank(user1);
        libraryContract.borrowBook(1);
        (uint256 bookId, uint256 borrowTime, bool active) = libraryContract.getUserBorrow(user1);
        assertEq(bookId, 1, "Book ID should be 1");
        assertEq(borrowTime, block.timestamp, "Borrow time should match");
        assertTrue(active, "Borrow should be active");
        (bookId, borrowTime, active) = libraryContract.getUserBorrow(user2);
        assertEq(bookId, 0, "Non-borrower book ID should be 0");
        assertEq(borrowTime, 0, "Non-borrower borrow time should be 0");
        assertFalse(active, "Non-borrower borrow should be inactive");
    }

    }

    
