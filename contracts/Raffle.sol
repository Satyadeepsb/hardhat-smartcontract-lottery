// Raffle

// Steps

// Enter the lottery (by paying some amount)
// Pick a random winner (verifiably random)
// Winner to be selected every X minutes -> completly automated (Event driven exectution)
// Chainlink Oracle -> Randomness, Automated Exectution (Chainlink Keepers)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error Raffle__NotEnoughETHEntered();

contract Raffle {
    /* State Variable */
    uint256 private immutable i_entraceFee;
    address payable[] private s_players;

    constructor(uint256 entraceFee) {
        i_entraceFee = entraceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        s_players.push(payable(msg.msg.sender))
    }

    // function pickRandomWinner() {}

    function getEntraceFee() public view returns (uint256) {
        return i_entraceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
