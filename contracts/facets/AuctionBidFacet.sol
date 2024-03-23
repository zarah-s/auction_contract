pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import "../interfaces/INFT.sol";

contract AuctionBidFacet {
    // event Stake(address _staker, uint256 _amount, uint256 _timeStaked);
    LibAppStorage.Layout internal l;
    event y(bool);

    function createAuction(
        address _contractAddress,
        uint _tokenId,
        uint _startingPrice,
        uint _closeTime
    ) external {
        require(_contractAddress != address(0), "INVALID_CONTRACT_ADDRESS");
        require(_closeTime > block.timestamp, "INVALID_CLOSE_TIME");
        INFT(_contractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        LibAppStorage.Auction memory _newAuction = LibAppStorage.Auction({
            id: l.auctions.length,
            author: msg.sender,
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            closeTime: _closeTime,
            nftContractAddress: _contractAddress,
            closed: false
        });
        l.auctions.push(_newAuction);
    }

    function calculatePercentageCut(uint amount) private pure returns (uint) {
        return (10 * amount) / 100;
    }

    function bid(uint auctionId, uint price) external {
        require(!l.auctions[auctionId].closed, "AUCTION_CLOSED");
        require(l.balances[msg.sender] > price, "INSUFFICIENT_BALANCE");
        // LibAppStorage.Bid storage bids = l.bids[auctionId];

        // emit y(l.bids[auctionId].length);
        if (l.bids[auctionId].length == 0) {
            // emit y(price);
            require(
                price >= l.auctions[auctionId].startingPrice,
                "STARTING_PRICE_MUST_BE_GREATER"
            );
            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        } else {
            require(
                price > l.bids[auctionId][l.bids[auctionId].length - 1].amount,
                "PRICE_MUST_BE_GREATER_THAN_LAST_BIDDED"
            );

            uint percentageCut = calculatePercentageCut(price);
            LibAppStorage._transferFrom(
                address(this),
                l.bids[auctionId][l.bids[auctionId].length - 1].author,
                l.bids[auctionId][l.bids[auctionId].length - 1].amount +
                    percentageCut
            );

            LibAppStorage.Bid memory _newBid = LibAppStorage.Bid({
                author: msg.sender,
                amount: price - percentageCut,
                auctionId: auctionId
            });
            l.bids[auctionId].push(_newBid);
        }
    }

    function closeAuction(uint auctionId) external {
        LibAppStorage.Auction storage auction = l.auctions[auctionId];

        require(!auction.closed, "AUCTION_CLOSED");
        require(
            l.bids[auctionId][l.bids[auctionId].length - 1].author ==
                msg.sender ||
                auction.author == msg.sender,
            "YOU_DONT_HAVE_RIGHT"
        );
        LibAppStorage._transferFrom(
            address(this),
            auction.author,
            l.bids[auctionId][l.bids[auctionId].length - 1].amount
        );

        INFT(auction.nftContractAddress).transferFrom(
            address(this),
            l.bids[auctionId][l.bids[auctionId].length - 1].author,
            auction.tokenId
        );
    }

    function getAuction(
        uint auctionId
    ) external view returns (LibAppStorage.Auction memory) {
        return l.auctions[auctionId];
    }

    function getBid(
        uint auctionId
    ) external view returns (LibAppStorage.Bid[] memory) {
        return l.bids[auctionId];
    }

    // error NoMoney(uint256 balance);

    // function stake(uint256 _amount) public {
    //     require(_amount > 0, "NotZero");
    //     require(msg.sender != address(0));
    //     uint256 balance = l.balances[msg.sender];
    //     require(balance >= _amount, "NotEnough");
    //     //transfer out tokens to self
    //     LibAppStorage._transferFrom(msg.sender, address(this), _amount);
    //     //do staking math
    //     LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
    //     s.stakedTime = block.timestamp;
    //     s.amount += _amount;
    //     emit Stake(msg.sender, _amount, block.timestamp);
    // }

    // function checkRewards(
    //     address _staker
    // ) public view returns (uint256 userPendingRewards) {
    //     LibAppStorage.UserStake memory s = l.userDetails[_staker];
    //     if (s.stakedTime > 0) {
    //         uint256 duration = block.timestamp - s.stakedTime;
    //         uint256 rewardPerYear = s.amount * LibAppStorage.APY;
    //         uint256 reward = rewardPerYear / 3154e7;
    //         userPendingRewards = reward * duration;
    //     }
    // }

    // event y(uint);

    // function unstake(uint256 _amount) public {
    //     LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
    //     uint256 reward = checkRewards(msg.sender);
    //     // require(s.amount >= _amount, "NoMoney");

    //     if (s.amount < _amount) revert NoMoney(s.amount);
    //     //unstake
    //     l.balances[address(this)] -= _amount;
    //     s.amount -= _amount;
    //     s.stakedTime = s.amount > 0 ? block.timestamp : 0;
    //     LibAppStorage._transferFrom(address(this), msg.sender, _amount);
    //     //check rewards

    //     emit y(reward);
    //     if (reward > 0) {
    //         IWOW(l.rewardToken).mint(msg.sender, reward);
    //     }
    // }
}

// interface IWOW {
//     function mint(address _to, uint256 _amount) external;
// }
