package hudson.security;

import hudson.security.LDAPSecurityRealm.AuthoritiesPopulatorImpl;
import junit.framework.TestCase;

import org.acegisecurity.ldap.DefaultInitialDirContextFactory;
import org.acegisecurity.ldap.InitialDirContextFactory;

public class LDAPSecurityRealmTest extends TestCase {

	public void testGroupMembershipRoles(){
		String URL = "ldaps://ldap.hp.com:636/";
		String groupBase = "ou=Groups,o=hp.com";
		InitialDirContextFactory initialDirContextFactory = new DefaultInitialDirContextFactory(URL);
		long startTime = System.currentTimeMillis();
		AuthoritiesPopulatorImpl impl = new LDAPSecurityRealm.AuthoritiesPopulatorImpl(initialDirContextFactory,groupBase);
		impl.getGroupMembershipRoles("uid=ye.liu@hp.com,ou=People,o=hp.com", "ye.liu@hp.com");
		long endTime = System.currentTimeMillis();
		System.out.println(endTime - startTime);
	}
}
