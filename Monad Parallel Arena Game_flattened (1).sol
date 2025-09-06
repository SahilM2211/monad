
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: Monad Parallel Arena Game.sol


pragma solidity ^0.8.20;



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

