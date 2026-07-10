public with sharing class ContactService {

    /**
     * Returns all active contacts for the given Account.
     */
    public static List<Contact> getActiveContacts(Id accountId) {

        if (accountId == null) {
            throw new IllegalArgumentException('Account Id cannot be null.');
        }

        return [
            SELECT Id,
                   FirstName,
                   LastName,
                   Email,
                   Phone
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastName
        ];
    }
}