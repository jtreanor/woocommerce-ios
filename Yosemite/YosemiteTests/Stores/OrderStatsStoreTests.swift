import XCTest
@testable import Yosemite
@testable import Networking


/// OrderStatsStore Unit Tests
///
class OrderStatsStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Dummy Site ID
    ///
    private let sampleSiteID = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    /// Verifies that OrderStatsAction.retrieveOrderStats returns the expected stats.
    ///
    func testRetrieveOrderStatsReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve order stats")
        let orderStatsStore = OrderStatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let remoteOrderStats = sampleOrderStats()

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "order-stats")
        let action = OrderStatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
                                                            XCTAssertNil(error)
                                                            guard let orderStats = orderStats,
                                                                let items = orderStats.items else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            XCTAssertEqual(items.count, 2)
                                                            XCTAssertEqual(orderStats, remoteOrderStats)
                                                            expectation.fulfill()
        }

        orderStatsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderStatsAction.retrieveOrderStats returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveOrderStatsReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order stats error response")
        let orderStatsStore = OrderStatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "sites/\(sampleSiteID)/stats/orders/", filename: "generic_error")
        let action = OrderStatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
                                                            XCTAssertNil(orderStats)
                                                            XCTAssertNotNil(error)
                                                            guard let _ = error else {
                                                                XCTFail()
                                                                return
                                                            }
                                                            expectation.fulfill()
        }

        orderStatsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderStatsAction.retrieveOrderStats returns an error whenever there is no backend response.
    ///
    func testRetrieveOrderNotesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve order stats empty response")
        let orderStatsStore = OrderStatsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = OrderStatsAction.retrieveOrderStats(siteID: sampleSiteID, granularity: .day,
                                                         latestDateToInclude: date(with: "2018-06-23T17:06:55"), quantity: 2) { (orderStats, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(orderStats)
            guard let _ = error else {
                XCTFail()
                return
            }
            expectation.fulfill()
        }

        orderStatsStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Private Methods
//
private extension OrderStatsStoreTests {

    func sampleOrderStats() -> OrderStats {
        return OrderStats(date: "2018-06-02",
                          granularity: .day,
                          quantity: "2",
                          fields: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                   "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                   "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
                          items: [sampleOrderStatsItem1(), sampleOrderStatsItem2()],
                          totalGrossSales: 439.23,
                          totalNetSales: 438.24,
                          totalOrders: 9,
                          totalProducts: 13,
                          averageGrossSales: 14.1687,
                          averageNetSales: 14.1368,
                          averageOrders: 0.2903,
                          averageProducts: 0.4194)
    }

    func sampleOrderStatsItem1() -> OrderStatsItem {
        return OrderStatsItem(fieldNames: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                           "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                           "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
                              rawData: ["2018-06-01", 2, 2, 0, 0, 14.24, 0.12, 9.9800000000000004, 0.28000000000000003, 0, 0, 0, 0, "USD", 14.24, 14.120000000000001, 7.1200000000000001, 1])
    }

    func sampleOrderStatsItem2() -> OrderStatsItem {
        return OrderStatsItem(fieldNames: ["period", "orders", "products", "coupons", "coupon_discount", "total_sales", "total_tax", "total_shipping",
                                           "total_shipping_tax", "total_refund", "total_tax_refund", "total_shipping_refund", "total_shipping_tax_refund",
                                           "currency", "gross_sales", "net_sales", "avg_order_value", "avg_products_per_order"],
                              rawData: ["2018-06-02", 1, 1, 0, 0, 30.870000000000001, 0.87, 0, 0, 0, 0, 0, 0, "USD", 30.870000000000001, 30, 30.870000000000001, 1])
    }

    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}