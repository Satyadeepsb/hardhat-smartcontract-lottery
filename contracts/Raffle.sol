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

error Raffle__NotEnoughETHEntered();

contract Raffle is VRFConsumerBaseV2 {
    /* State Variable */
    uint256 private immutable i_entraceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;

    /* Events */
    event RaffleEnter(address indexed players);

    constructor(
        address vrfCoordinatorV2,
        uint256 entraceFee,
        bytes32 gasLane
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entraceFee = entraceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.sender));
        // Emit an event when we update a dynamic array or mapping
        // Named events with the function name reversed
        emit RaffleEnter(msg.sender);
    }

    function requestRandomWinner() external {
        // Request the random number
        // Once we get it, do something with it
        // 2 transaction process
        // i_vrfCoordinator.requestRandomWords(
        //     i_gasLane,
        //     s_subscriptionId,
        //     requestConfirmations,
        //     callbackGasLimit,
        //     numWords
        // );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randowmWords
    ) internal override {}

    /* View / Pure Functions  */
    function getEntraceFee() public view returns (uint256) {
        return i_entraceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
