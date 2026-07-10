@isTest
public class ContactServiceTest {

    @isTest
    static void testGetActiveContacts() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Smith',
            Email = 'john@test.com',
            AccountId = acc.Id
        );
        insert con;

        Test.startTest();

        List<Contact> contacts = ContactService.getActiveContacts(acc.Id);

        Test.stopTest();

        System.assertEquals(1, contacts.size());
        System.assertEquals('John', contacts[0].FirstName);
    }
}