/*****************************************************************
Name:          ContactServiceTest
============================================================
Purpose:       Unit test class for ContactService.
               Covers: happy path, bulk scenario (200 records),
               empty result set, null input exception, and
               verifies ContactServiceException propagation.
               Target coverage: 90%+
============================================================
History
-------
VERSION  AUTHOR              DATE         DETAIL      DESCRIPTION
1.0      Revecast Orchestrate 2026-07-10  Created     Initial test suite
*****************************************************************/
@isTest
private class ContactServiceTest {

    // ─── Test Data Factory ────────────────────────────────────────────────────

    /*****************************************************************
    Purpose:      Creates a test Account and optionally N Contacts
                  linked to it. All data is committed inside
                  @testSetup so individual methods share it.
    *****************************************************************/
    @testSetup
    static void setupTestData() {
        // Create primary test Account
        Account testAccount = new Account(
            Name = 'Test Account — ContactService'
        );
        insert testAccount;

        // Create 200 Contacts linked to the Account (bulk scenario)
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 1; i <= 200; i++) {
            contacts.add(new Contact(
                FirstName   = 'Test',
                LastName    = 'Contact ' + i,
                Phone       = '555-000-' + String.valueOf(i).leftPad(4, '0'),
                AccountId   = testAccount.Id
            ));
        }
        insert contacts;
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Test Account — ContactService' LIMIT 1];
    }

    // ─── Test Methods ─────────────────────────────────────────────────────────

    /*****************************************************************
    Purpose:      Happy path — verifies the method returns all 200
                  Contacts for a valid Account ID.
    Data:         200 Contacts linked to test Account (from @testSetup)
    Expected:     List of 200 Contact records returned
    *****************************************************************/
    @isTest
    static void testGetContactsByAccountId_HappyPath() {
        // Arrange
        Account testAccount = getTestAccount();

        // Act
        Test.startTest();
        ContactService service = new ContactService();
        List<Contact> result = service.getContactsByAccountId(testAccount.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(200, result.size(),
            'Should return all 200 Contacts for the Account.');
        System.assertEquals(testAccount.Id, result[0].AccountId,
            'Returned Contacts should belong to the test Account.');
    }

    /*****************************************************************
    Purpose:      Bulk scenario — explicitly exercises 200-record
                  retrieval to confirm governor-limit safety.
    Data:         200 Contacts from @testSetup
    Expected:     200 records returned, all fields populated
    *****************************************************************/
    @isTest
    static void testGetContactsByAccountId_BulkScenario() {
        // Arrange
        Account testAccount = getTestAccount();

        // Act
        Test.startTest();
        ContactService service = new ContactService();
        List<Contact> result = service.getContactsByAccountId(testAccount.Id);
        Test.stopTest();

        // Assert — 200 records, spot-check required fields populated
        System.assertEquals(200, result.size(),
            'Bulk: should handle 200 records without hitting governor limits.');

        for (Contact c : result) {
            System.assertNotEquals(null, c.Id,          'Contact Id must be set.');
            System.assertNotEquals(null, c.LastName,    'LastName must be set.');
            System.assertEquals(testAccount.Id, c.AccountId,
                'Every Contact AccountId must match the queried Account.');
        }
    }

    /*****************************************************************
    Purpose:      Empty result — verifies the method returns an empty
                  list (not null) for an Account with no Contacts.
    Data:         A fresh Account with zero Contacts inserted
    Expected:     Empty List<Contact>, no exception thrown
    *****************************************************************/
    @isTest
    static void testGetContactsByAccountId_NoContacts() {
        // Arrange — Account with no Contacts
        Account emptyAccount = new Account(Name = 'Empty Account — No Contacts');
        insert emptyAccount;

        // Act
        Test.startTest();
        ContactService service = new ContactService();
        List<Contact> result = service.getContactsByAccountId(emptyAccount.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result,
            'Result must never be null — empty list expected.');
        System.assertEquals(0, result.size(),
            'Should return an empty list when no Contacts exist for the Account.');
    }

    /*****************************************************************
    Purpose:      Null input — verifies ContactServiceException is
                  thrown when a null Account ID is passed.
    Data:         null Id
    Expected:     ContactService.ContactServiceException thrown
    *****************************************************************/
    @isTest
    static void testGetContactsByAccountId_NullAccountId() {
        // Arrange
        ContactService service = new ContactService();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        // Act
        Test.startTest();
        try {
            service.getContactsByAccountId(null);
        } catch (ContactService.ContactServiceException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Assert
        System.assertEquals(true, exceptionThrown,
            'A ContactServiceException must be thrown for a null Account ID.');
        System.assert(exceptionMessage.contains('must not be null'),
            'Exception message should indicate null Account ID. Got: ' + exceptionMessage);
    }

    /*****************************************************************
    Purpose:      Result ordering — verifies Contacts are returned
                  sorted by LastName then FirstName ascending.
    Data:         3 Contacts with known names
    Expected:     Results ordered Alpha, Beta, Gamma by LastName
    *****************************************************************/
    @isTest
    static void testGetContactsByAccountId_ResultOrdering() {
        // Arrange — create a dedicated Account and 3 named Contacts
        Account orderAccount = new Account(Name = 'Order Test Account');
        insert orderAccount;

        List<Contact> unorderedContacts = new List<Contact>{
            new Contact(LastName = 'Gamma', FirstName = 'G', AccountId = orderAccount.Id),
            new Contact(LastName = 'Alpha', FirstName = 'A', AccountId = orderAccount.Id),
            new Contact(LastName = 'Beta',  FirstName = 'B', AccountId = orderAccount.Id)
        };
        insert unorderedContacts;

        // Act
        Test.startTest();
        ContactService service = new ContactService();
        List<Contact> result = service.getContactsByAccountId(orderAccount.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(3, result.size(), 'Should return exactly 3 Contacts.');
        System.assertEquals('Alpha', result[0].LastName, 'First result should be Alpha.');
        System.assertEquals('Beta',  result[1].LastName, 'Second result should be Beta.');
        System.assertEquals('Gamma', result[2].LastName, 'Third result should be Gamma.');
    }
}
