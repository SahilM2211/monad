// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ParallelArena
 * @author [Your Name]
 * @notice An on-chain arena game designed to showcase Monad's parallel execution.
 * Players can enter an arena, move around a 2D grid, and attack each other in real-time.
 * Each action is an independent transaction, which Monad can process concurrently.
 */
contract ParallelArena is Ownable, ReentrancyGuard {

    // --- Events ---
    event PlayerJoined(address indexed player, uint256 playerId, uint x, uint y);
    event PlayerMoved(uint256 indexed playerId, uint newX, uint newY);
    event PlayerAttacked(uint256 indexed attackerId, uint256 indexed targetId, uint256 damage, uint256 targetHealth);
    event PlayerDefeated(uint256 indexed winnerId, uint256 indexed loserId);

    // --- Structs ---
    struct Player {
        uint256 id;
        address owner;
        uint256 health;
        uint256 attackPower;
        uint256 x;
        uint256 y;
        bool inArena;
    }

    // --- State Variables ---
    uint256 public constant MAX_HEALTH = 100;
    uint256 public constant BASE_ATTACK = 10;
    uint256 public constant ARENA_WIDTH = 1000;
    uint256 public constant ARENA_HEIGHT = 1000;

    Player[] public players;
    mapping(address => uint256) public playerIds;
    mapping(uint256 => mapping(uint256 => bool)) public positionOccupied; // Keeps track of occupied coordinates

    uint256 private nextPlayerId = 1; // Start player IDs from 1

    // --- Modifiers ---
    modifier onlyInArena() {
        require(playerIds[msg.sender] != 0, "You are not in the arena");
        require(players[playerIds[msg.sender] - 1].inArena, "Player is not active in the arena");
        _;
    }

    constructor() Ownable(msg.sender) {}

    // --- Public Functions ---

    /**
     * @notice Allows a new player to join the arena.
     * They are spawned at a random, unoccupied position.
     */
    function joinArena() external nonReentrant {
        require(playerIds[msg.sender] == 0, "You are already in the arena");

        uint256 playerId = nextPlayerId++;
        playerIds[msg.sender] = playerId;

        // Find a random unoccupied spawn point
        uint256 spawnX;
        uint256 spawnY;
        uint256 attempts = 0;
        do {
            // A simple pseudo-random generator. Not for production security.
            spawnX = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, attempts))) % ARENA_WIDTH;
            // FIXED: Replaced deprecated `block.difficulty` with `block.prevrandao`
            spawnY = uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, attempts))) % ARENA_HEIGHT;
            attempts++;
            require(attempts < 50, "Could not find a spawn point"); // Prevent infinite loops
        } while (positionOccupied[spawnX][spawnY]);

        positionOccupied[spawnX][spawnY] = true;

        players.push(Player({
            id: playerId,
            owner: msg.sender,
            health: MAX_HEALTH,
            attackPower: BASE_ATTACK,
            x: spawnX,
            y: spawnY,
            inArena: true
        }));

        emit PlayerJoined(msg.sender, playerId, spawnX, spawnY);
    }

    /**
     * @notice Moves the player's character to a new coordinate on the grid.
     * @dev This is a high-frequency action that benefits from parallel execution.
     * @param newX The new X coordinate.
     * @param newY The new Y coordinate.
     */
    function move(uint256 newX, uint256 newY) external onlyInArena nonReentrant {
        require(newX < ARENA_WIDTH && newY < ARENA_HEIGHT, "Coordinates out of bounds");
        require(!positionOccupied[newX][newY], "Position is already occupied");

        uint256 playerId = playerIds[msg.sender] - 1;
        Player storage player = players[playerId];

        // Free up the old position
        positionOccupied[player.x][player.y] = false;

        // Occupy the new position
        player.x = newX;
        player.y = newY;
        positionOccupied[newX][newY] = true;

        emit PlayerMoved(player.id, newX, newY);
    }

    /**
     * @notice Allows a player to attack another player.
     * @dev Many attacks can happen in the same block, perfect for Monad's architecture.
     * @param targetId The ID of the player to attack.
     */
    function attack(uint256 targetId) external onlyInArena nonReentrant {
        require(targetId > 0 && targetId <= players.length, "Invalid target ID");

        uint256 attackerId = playerIds[msg.sender] - 1;
        uint256 targetIndex = targetId - 1;

        Player storage attacker = players[attackerId];
        Player storage target = players[targetIndex];

        require(attacker.id != target.id, "Cannot attack yourself");
        require(target.inArena, "Target is not in the arena");

        // Simple distance check (Manhattan distance)
        uint256 distance = abs(attacker.x, target.x) + abs(attacker.y, target.y);
        require(distance <= 1, "Target is out of range"); // Must be in an adjacent square

        uint256 damage = attacker.attackPower;

        if (target.health <= damage) {
            target.health = 0;
            target.inArena = false;
            // Free up the defeated player's position
            positionOccupied[target.x][target.y] = false;
            emit PlayerDefeated(attacker.id, target.id);
        } else {
            target.health -= damage;
        }

        emit PlayerAttacked(attacker.id, target.id, damage, target.health);
    }

    // --- View Functions ---

    /**
     * @notice Gets the details of a specific player.
     * @param playerId The ID of the player.
     * @return id The player's unique ID.
     * @return owner The wallet address of the player.
     * @return health The player's current health.
     * @return x The player's X coordinate.
     * @return y The player's Y coordinate.
     * @return inArena The player's status in the arena.
     */
    function getPlayer(uint256 playerId) external view returns (uint256 id, address owner, uint256 health, uint256 x, uint256 y, bool inArena) {
        require(playerId > 0 && playerId <= players.length, "Invalid player ID");
        Player storage player = players[playerId - 1];
        return (player.id, player.owner, player.health, player.x, player.y, player.inArena);
    }

    /**
     * @notice Gets a player's ID from their wallet address.
     * @param owner The address of the player.
     * @return The player's ID.
     */
    function getPlayerIdByOwner(address owner) external view returns (uint256) {
        return playerIds[owner];
    }



    // --- Helper Function ---
    function abs(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a - b : b - a;
    }
}

