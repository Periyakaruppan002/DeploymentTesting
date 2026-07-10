/*****************************************************************
Name:          ContactService
============================================================
Purpose:       Service class providing Contact retrieval operations.
               Exposes a method to fetch all Contact records
               associated with a given Account ID.
============================================================
History
-------
VERSION  AUTHOR              DATE         DETAIL      DESCRIPTION
1.0      Revecast Orchestrate 2026-07-10  Created     Initial build — ContactService
*****************************************************************/
public with sharing class ContactService {

    // ─── Constants ────────────────────────────────────────────────────────────

    private static final String ERROR_NULL_ACCOUNT_ID =
        'Account ID must not be null.';
    private static final String ERROR_QUERY_FAILED =
        'An error occurred while retrieving Contacts: ';

    // ─── Public Methods ───────────────────────────────────────────────────────

    /*****************************************************************
    Purpose:      Returns all Contact records linked to the specified
                  Account ID. Includes standard biographical fields
                  and is safe to call in bulk-trigger contexts.
    Parameters:   accountId (Id) — the Account record to query against
    Returns:      List<Contact> — may be empty; never null
    Throws:       ContactServiceException — on null input or query failure
    History
    --------
    VERSION  AUTHOR              DATE         DETAIL
    1.0      Revecast Orchestrate 2026-07-10  Created
    *****************************************************************/
    public List<Contact> getContactsByAccountId(Id accountId) {
        System.debug('Entering ContactService.getContactsByAccountId: accountId=' + accountId);

        if (accountId == null) {
            throw new ContactServiceException(ERROR_NULL_ACCOUNT_ID);
        }

        List<Contact> contacts = new List<Contact>();

        try {
            contacts = [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Email,
                    Phone,
                    Title,
                    AccountId
                FROM Contact
                WHERE AccountId = :accountId
                ORDER BY LastName, FirstName ASC
            ];
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR,
                'ContactService.getContactsByAccountId — QueryException: ' + qe.getMessage());
            throw new ContactServiceException(ERROR_QUERY_FAILED + qe.getMessage(), qe);
        }

        System.debug('Exiting ContactService.getContactsByAccountId: returned '
            + contacts.size() + ' record(s)');
        return contacts;
    }

    // ─── Inner Exception Class ────────────────────────────────────────────────

    /*****************************************************************
    Purpose:      Custom exception type for ContactService errors.
                  Allows callers to catch service-specific failures
                  without swallowing all exceptions.
    *****************************************************************/
    public class ContactServiceException extends Exception {}
}
