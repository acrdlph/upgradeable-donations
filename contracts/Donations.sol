pragma solidity 0.4.24;

import "openzeppelin-eth/contracts/token/ERC721/ERC721Mintable.sol";
import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/ownership/Ownable.sol";
import "zos-lib/contracts/Initializable.sol";

/**
 * @title Donations
 */
contract Donations is Initializable, Ownable {

    using SafeMath for uint256;

    event Withdrawal(address indexed wallet, uint256 value);
    event NewDonation(address indexed donor, uint256 value);

    // ERC721 non-fungible tokens to be emitted on donations.
    ERC721Mintable public token;
    uint256 public numEmittedTokens;
    // These are our initial state variables:
    uint256 public minDonation;
    string public contractName;
    // The initialize function acts as a constructor, that can be called from outside
    function initialize(uint256 _minDonation, string _contractName) initializer public {
        minDonation = _minDonation;
        contractName = _contractName;
    }

    function donate() public payable {
        require(msg.value > minDonation, "Send more ETH!!");
        emit NewDonation(msg.sender, msg.value);
        emitUniqueToken(msg.sender);
    }

    function setToken(ERC721Mintable _token) external onlyOwner {
        require(_token != address(0));
        require(token == address(0));
        token = _token;
    }

    function emitUniqueToken(address _tokenOwner) internal {
        token.mint(_tokenOwner, numEmittedTokens);
        numEmittedTokens = numEmittedTokens.add(1);
    }

    function withdraw(address wallet) public onlyOwner {
        require(address(this).balance > 0, "No funds in contract");
        require(wallet != address(0));
        uint256 value = address(this).balance;
        wallet.transfer(value);
        emit Withdrawal(wallet, value);
    }

    function reduceMinDonation() public {
        minDonation -= 1;
    }
}

