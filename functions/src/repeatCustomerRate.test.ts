import { computeRepeatCustomerRates, CompletedAppointment } from "./repeatCustomerRate";

describe("computeRepeatCustomerRates", () => {
  it("returns 0% when every customer visited exactly once", () => {
    const appointments: CompletedAppointment[] = [
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-2" },
      { businessId: "biz-a", customerId: "cust-3" },
    ];

    const result = computeRepeatCustomerRates(appointments);

    expect(result).toEqual([
      { businessId: "biz-a", totalCustomers: 3, repeatCustomers: 0, repeatCustomerRate: 0 },
    ]);
  });

  it("computes the correct percentage with a mix of repeat and single-visit customers", () => {
    const appointments: CompletedAppointment[] = [
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" }, // repeat
      { businessId: "biz-a", customerId: "cust-2" },
      { businessId: "biz-a", customerId: "cust-3" },
      { businessId: "biz-a", customerId: "cust-4" },
    ];
    // 4 distinct customers, 1 repeat -> 25%

    const result = computeRepeatCustomerRates(appointments);

    expect(result).toEqual([
      { businessId: "biz-a", totalCustomers: 4, repeatCustomers: 1, repeatCustomerRate: 25 },
    ]);
  });

  it("excludes the 'customer-demo' guest fallback id entirely, not just from the repeat count", () => {
    const appointments: CompletedAppointment[] = [
      { businessId: "biz-a", customerId: "customer-demo" },
      { businessId: "biz-a", customerId: "customer-demo" },
      { businessId: "biz-a", customerId: "customer-demo" },
      { businessId: "biz-a", customerId: "cust-1" },
    ];
    // Without exclusion this would look like a heavily-repeating customer
    // inflating the rate; with exclusion only cust-1 remains, single visit.

    const result = computeRepeatCustomerRates(appointments);

    expect(result).toEqual([
      { businessId: "biz-a", totalCustomers: 1, repeatCustomers: 0, repeatCustomerRate: 0 },
    ]);
  });

  it("returns an empty array for empty input, without throwing", () => {
    expect(computeRepeatCustomerRates([])).toEqual([]);
  });

  it("counts a customer with many repeat visits as exactly one repeat customer, not weighted by visit count", () => {
    const appointments: CompletedAppointment[] = [
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" }, // 5 visits total
      { businessId: "biz-a", customerId: "cust-2" }, // single visit
    ];
    // 2 distinct customers, 1 repeat -> 50%, regardless of cust-1's 5 visits

    const result = computeRepeatCustomerRates(appointments);

    expect(result).toEqual([
      { businessId: "biz-a", totalCustomers: 2, repeatCustomers: 1, repeatCustomerRate: 50 },
    ]);
  });

  it("computes rates independently per business when multiple businesses are present", () => {
    const appointments: CompletedAppointment[] = [
      // biz-a: 2 customers, 1 repeat -> 50%
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-1" },
      { businessId: "biz-a", customerId: "cust-2" },
      // biz-b: 2 customers, 0 repeats -> 0%
      { businessId: "biz-b", customerId: "cust-3" },
      { businessId: "biz-b", customerId: "cust-4" },
    ];

    const result = computeRepeatCustomerRates(appointments);

    expect(result).toHaveLength(2);
    expect(result).toEqual(
      expect.arrayContaining([
        { businessId: "biz-a", totalCustomers: 2, repeatCustomers: 1, repeatCustomerRate: 50 },
        { businessId: "biz-b", totalCustomers: 2, repeatCustomers: 0, repeatCustomerRate: 0 },
      ])
    );
  });
});