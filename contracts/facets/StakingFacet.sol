pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract StakingFacet {
    event Stake(address _staker, uint256 _amount, uint256 _timeStaked);
    LibAppStorage.Layout internal l;

    error NoMoney(uint256 balance);

    function stake(uint256 _amount) public {
        require(_amount > 0, "NotZero");
        require(msg.sender != address(0));
        uint256 balance = l.balances[msg.sender];
        require(balance >= _amount, "NotEnough");
        //transfer out tokens to self
        LibAppStorage._transferFrom(msg.sender, address(this), _amount);
        //do staking math
        LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
        s.stakedTime = block.timestamp;
        s.amount += _amount;
        emit Stake(msg.sender, _amount, block.timestamp);
    }

    function checkRewards(
        address _staker
    ) public view returns (uint256 userPendingRewards) {
        LibAppStorage.UserStake memory s = l.userDetails[_staker];
        if (s.stakedTime > 0) {
            uint256 duration = block.timestamp - s.stakedTime;
            uint256 rewardPerYear = s.amount * LibAppStorage.APY;
            uint256 reward = rewardPerYear / 3154e7;
            userPendingRewards = reward * duration;
        }
    }

    event y(uint);

    function unstake(uint256 _amount) public {
        LibAppStorage.UserStake storage s = l.userDetails[msg.sender];
        uint256 reward = checkRewards(msg.sender);
        // require(s.amount >= _amount, "NoMoney");

        if (s.amount < _amount) revert NoMoney(s.amount);
        //unstake
        l.balances[address(this)] -= _amount;
        s.amount -= _amount;
        s.stakedTime = s.amount > 0 ? block.timestamp : 0;
        LibAppStorage._transferFrom(address(this), msg.sender, _amount);
        //check rewards

        emit y(reward);
        if (reward > 0) {
            IWOW(l.rewardToken).mint(msg.sender, reward);
        }
    }
}

interface IWOW {
    function mint(address _to, uint256 _amount) external;
}
