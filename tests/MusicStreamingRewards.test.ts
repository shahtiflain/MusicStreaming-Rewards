import { describe, it, expect, beforeAll } from "vitest";
import { initSimnet } from "@hirosystems/clarinet-sdk"; // SDK import

describe("MusicStreamingRewards Contract Test", () => {
  let simnet: any;
  let accounts: any;
  let address1: any;

  // ✅ Setup before running tests
  beforeAll(async () => {
    simnet = await initSimnet();
    accounts = simnet.getAccounts();
    address1 = accounts.get("wallet_1");
  });

  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("calls example read-only function", () => {
    const { result } = simnet.callReadOnlyFn(
      "counter",       // contract name
      "get-counter",   // function name
      [],              // arguments
      address1         // caller address
    );

    // Clarinet's style check
    result.expectOk().expectUint(0);

    // OR Vitest matcher if available
    // expect(result).toBeUint(0);
  });
});
