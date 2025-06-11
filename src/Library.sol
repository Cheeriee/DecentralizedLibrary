// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Library {
    address public admin;

    error OnlyAdmin();
    error InvalidInput();
    error BookNotFound();
    error BookAlreadyBorrowed();
    error NoActiveBorrow();
    error NoCopiesAvailable();
    error InvalidBookId();


    event BookAdded(uint256 indexed bookId, string author,string title, uint256 totalCopies);
    event BookBorrowed(address indexed user, uint256 indexed bookId, uint256 borrowTime);
    event BookReturned(address indexed user, uint256 indexed bookId, uint256 returnTime);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);


    struct Book{ //struct to store book details
        uint256 id;
        string title;
        string author;
        uint256 totalCopies;
        uint256 availableCopies;
        bool exists;
    }

    struct Borrow{ //struct to store borrow details
        uint256 bookId;
        uint256 borrowTime;
        bool active;
    }

    mapping(uint256 => Book) public books; //mapping from book ID to book struct
    mapping(address => Borrow) public userBorrows; //mapping from user address to their borrowed books
    uint256 private nextBookId; //counter for generating unique IDs

    constructor() {
        admin = msg.sender;
        nextBookId = 1;
    }

    modifier onlyAdmin() {
        if(msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }

function addBook(string memory title, string memory author, uint256 totalCopies) external onlyAdmin {
    if(bytes(title).length == 0) {
        revert InvalidInput();
    }
    if(bytes(author).length == 0) {
        revert InvalidInput();
    }
    if(totalCopies == 0) {
        revert InvalidInput();
    }

    books[nextBookId] = Book({ //store book
        id: nextBookId,
        title: title,
        author: author,
        totalCopies: totalCopies,
        availableCopies: totalCopies,
        exists: true
        });

    emit BookAdded(nextBookId, author,title, totalCopies);

    nextBookId++ //increment book ID for next book
}

function borrowBook(uint256 bookId) external {
    Book storage book = books[bookId]; //make reference to the book struct to check if the book exists.
    if(!book.exists) {
        revert BookNotFound();
    }
    if(book.availableCopies == 0){
        revert NoCopiesAvailable();
    }
    if(userBorrows[msg.sender].active) {
        revert BookAlreadyBorrowed();
    }

    book.availableCopies--; //update book availability

    userBorrows[msg.sender] = Borrow({ //record borrow
        bookId: bookId,
        borrowTime: block.timestamp,
        active: true
    });

    emit BookBorrowed(msg.sender, bookId, block.timestamp);
}

function returnBook() external {
    Borrow storage borrow = userBorrows[msg.sender]; //check if user has an active borrow
    if(!borrow.active) {
        revert NoActiveBorrow();
    }
    
    Book storage book = books[borrow.bookId]; //check if book exixts
    if(!book.exists) {
        revert BookNotFound();
    }

    book.availableCopies++; //update availability

    borrow.active: false;
    borrow.bookId: 0;
    borrow.borrowTime: 0;

    emit BookReturned(msg.sender, book.id, block.timestamp);
}

function transferAdmin(address newAdmin) external onlyAdmin {
    if(newAdmin = address(0)) {
        revert InvalidInput();
    }
    address oldAdmin = admin;
    admin = newAdmin;

    emit AdminChanged(oldAdmin, newAdmin);
}

function getBookDetails(uint256 bookId) external view returns(
    string memory title, 
    string memory author, 
    uint256 totalCopies, 
    uint256 availableCopies) {
        Book storage book = books[bookId];
        if(!book.exists) {
            revert BookNotFound();
        }

        return(book.title, book.author, book.totalCopies, book.availableCopies);
    }

function getUserBorrow(address user) external view returns( //checks if a user has an active borrow
    uint256 bookId,
    uint256 borrowTime,
    bool active){
        Borrow storage borrow = userBorrows[user];
        return(borrow.bookId, borrow.borrowTime, borr.active);
    }
}