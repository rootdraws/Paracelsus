Let's construct an Ownership Hierarchy Map based on your smart contract ecosystem, which includes `RugFactory`, `PoolRegistry`, and multiple instances of `PoolWarden`. This hierarchy will clarify the relationships and control mechanisms between these contracts.

### Ownership Hierarchy Map

1. **RugFactory (Central Admin)**
    - **Owns**: `PoolRegistry` and indirectly owns all `PoolWarden` instances created by it.
    - **Controlled Functions**:
        - `createCampaign`: Public to the owner. Creates a new `PoolWarden` and registers it with the `PoolRegistry`.
        - `triggerDistribution`: Public to the owner. Triggers the distribution phase of a specific `PoolWarden`.
        - `triggerDepositLP`: Public to the owner. Initiates LP token seeding for a specific `PoolWarden`.
    - **Public Functions**: None that modify contract states, but acts as a central authority for campaign creation and management.

2. **PoolRegistry**
    - **Owned By**: `RugFactory`.
    - **Controlled Functions**:
        - `registerCampaign`: Public to the owner (`RugFactory`). Registers a new campaign with its `poolWarden` and `lpToken`.
        - `recordContribution`: Public (should ideally be restricted to `PoolWarden` instances or `RugFactory` to ensure data integrity). Records contributions to campaigns.
        - `triggerDistributionForCampaign`: Public to the owner. Marks a campaign as having completed distribution.
    - **Public Functions**: Functions related to fetching campaign data for transparency, like viewing registered campaigns and contributions.

3. **PoolWarden (Multiple Instances)**
    - **Owned By**: Contract creator (implicitly `RugFactory` upon deployment).
    - **Controlled Functions**:
        - `yeet`: Public. Allows contributions to be made to the campaign until the deadline.
        - `distribution`: Public (might consider restrictions or ownership checks for triggering distribution to prevent unauthorized access).
        - `seedLP`: Public (should include ownership checks or similar restrictions to ensure only authorized entities can trigger it).
    - **Interactions**:
        - All instances interact with `PoolRegistry` for functions like recording contributions and triggering distribution phases.

### Modular Setup for Distribution Logic

- **Problem**: Need a mechanism for each `PoolWarden` to interact with `PoolRegistry` for distribution based on individual contributions.
- **Solution**: Implement a distribution logic module that can read each campaign's contribution data from `PoolRegistry` and execute distribution logic based on the total amount contributed per contributor versus the total tokens to be distributed.
- **Execution**:
    - **PoolRegistry Enhancements**: Augment `PoolRegistry` with functions to facilitate detailed contribution data retrieval and distribution logic execution.
    - **PoolWarden Calls**: Each `PoolWarden` instance should call these enhanced functions in `PoolRegistry` when executing distribution to ensure each contributor receives their rightful share based on their contribution.

### Security and Data Integrity

- Ensure that only authorized calls (e.g., from `PoolWarden` instances created by `RugFactory`) can trigger significant state changes in `PoolRegistry`.
- Consider using `modifier`s in `PoolRegistry` to restrict which contracts (or addresses) can call sensitive functions, enhancing the ecosystem's security.

### Conclusion

This setup allows `RugFactory` to maintain central control over the campaign creation and management process while enabling a transparent, decentralized mechanism for campaign contributions and distributions. The `PoolRegistry` acts as the central data layer, ensuring data integrity and facilitating complex interactions between `RugFactory` and multiple `PoolWarden` instances.