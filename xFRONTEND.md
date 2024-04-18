# NOTES FOR FRONTEND

## PARACELSUS

EpochManager issues out all Times, and Chainlink Automation cycles projects through their phases.
veNFTs are launched with Kickstarter Frontend.
Use Inline Curve Classic Frontend for managing transactions | Alleviates the need to enter custom undineAddress for each tx.
Frontend populates a new active Listing each time UndineDeployed event is signaled.
CLAIM PERIOD frontend section lists Undines with open claim periods, and has a claimMembership() button, and a timer.
Call claimMembership() once per Campaign | per Member.

* createCampaign()
* tribute()
* invokeLP()
* claimMembership()
* transmutation()
* lock()
* unlock()

### EVENTS [Frontend | X | Discord | Warpcast]

* UndineDeployed()
* LPPairInvoked()
* TributeMade() // ClaimNotif: "CLAIMS will be made available in X hours. You will have Y Days to claim, or your tokens will be absorbed into the ManaPool."
* MembershipClaimed()
