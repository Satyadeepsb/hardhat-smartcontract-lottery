// Raffle

// Steps

// Enter the lottery (by paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes -> completly automated (Event driven exectution)
// Chainlink Oracle -> Randomness, Automated Exectution (Chainlink Keepers)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TranferFailed();
error Raffle__NotOpen();

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    } // uint256 0 = OPEN, 1 = CALCULATING

    /* State Variable */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_interval;

    /* Lottery Variables */
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastTimestamp;

    /* Events */
    event RaffleEnter(address indexed players);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_entranceFee = entranceFee;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        // Emit an event when we update a dynamic array or mapping
        // Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    function performUpkeep(bytes calldata /* performData */) external {
        // Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedRaffleWinner(requestId);
    }

    /**
     *
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for the `upkeepNeeded` to return true.
     * 1. Our time interval should have passed
     * 2. The lottery should have at least 1 player, and have some ETH
     * 3. Our subscription is funded with LINK
     * 4. Lottery should be in an "open" state
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        // block.timestamp - last block timestamp
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasBalance && hasPlayers);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randowmWords
    ) internal override {
        // s_players size 20
        // randomNumber 202
        // 202 % 10 = 2
        uint256 indexOfWinner = randowmWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if (!success) {
            revert Raffle__TranferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View / Pure Functions  */
    function getEntraceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }
}
