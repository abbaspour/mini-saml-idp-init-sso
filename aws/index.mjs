import {SignedXml} from "xml-crypto";
import crypto from "crypto";
import fs from "fs";

// noinspection DuplicatedCode

// AWS Lambda handler function
// noinspection JSUnusedGlobalSymbols
export const handler = async (event, context) => {

    try {
        // Load your private key and certificate
        const privateKey = fs.readFileSync('private.pem', 'utf-8');
        const certificate = fs.readFileSync('cert.pem', 'utf-8');

        // Parse nameID from query parameters
        const queryStringParameters = event.queryStringParameters || {};
        const nameID = queryStringParameters.nameID || 'default@example.com'; // Default value if not provided

        // Generate IDs and timestamps
        const responseID = generateUniqueID();
        const assertionID = generateUniqueID();
        const issueInstant = getCurrentTime();
        const notOnOrAfter = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // Valid for 5 min

        // User information (could be dynamically loaded based on event input)
        const user = {
            nameID: nameID, // Replace or use event input for dynamic values
            attributes: [
                {
                    Name: 'email',
                    Value: 'user@example.com',
                    NameFormat: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    Type: 'xs:string'
                },
                {
                    Name: 'lastName',
                    Value: 'Doe',
                    NameFormat: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    Type: 'xs:string'
                },
                {
                    Name: 'firstName',
                    Value: 'John',
                    NameFormat: 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    Type: 'xs:string'
                },
                {
                    Name: 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn',
                    Value: 'user@example.com',
                    NameFormat: 'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
                    Type: 'xs:string'
                },
            ],
        };

        // Service Provider information
        const recipient = process.env.SAML_REDIRECT_LOCATION;//'https://idp-initiated-saml-demo.au.auth0.com/login/callback?connection=idp-init-saml';
        const audience = process.env.SAML_AUDIENCE; //'urn:auth0:idp-initiated-saml-demo:idp-init-saml';
        const issuer = process.env.SAML_ISSUER; // 'urn:idp-init-saml.abbaspour.workers.dev';

        // Build the Assertion XML
        let assertion = `<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" Version="2.0" ID="${assertionID}" IssueInstant="${issueInstant}">
          <saml:Issuer>${issuer}</saml:Issuer>
          <!-- Signature will be inserted here -->
          <saml:Subject>
            <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">${user.nameID}</saml:NameID>
            <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
              <saml:SubjectConfirmationData NotOnOrAfter="${notOnOrAfter}" Recipient="${recipient}"/>
            </saml:SubjectConfirmation>
          </saml:Subject>
          <saml:Conditions NotBefore="${issueInstant}" NotOnOrAfter="${notOnOrAfter}">
            <saml:AudienceRestriction>
              <saml:Audience>${audience}</saml:Audience>
            </saml:AudienceRestriction>
          </saml:Conditions>
          <saml:AuthnStatement AuthnInstant="${issueInstant}" SessionIndex="${generateUniqueID()}">
            <saml:AuthnContext>
              <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml:AuthnContextClassRef>
            </saml:AuthnContext>
          </saml:AuthnStatement>
          <saml:AttributeStatement xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            ${user.attributes.map(attr => `
            <saml:Attribute Name="${attr.Name}" NameFormat="${attr.NameFormat}">
              <saml:AttributeValue xsi:type="${attr.Type}">${attr.Value}</saml:AttributeValue>
            </saml:Attribute>`).join('')}
          </saml:AttributeStatement>
        </saml:Assertion>`;

        // Create a SignedXml object
        const sig = new SignedXml();

        // Set the signature and canonicalization algorithms
        sig.signatureAlgorithm = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
        sig.canonicalizationAlgorithm = 'http://www.w3.org/2001/10/xml-exc-c14n#';

        // Add a reference to the Assertion element
        sig.addReference(
            "//*[local-name(.)='Assertion']",
            [
                'http://www.w3.org/2000/09/xmldsig#enveloped-signature',
                'http://www.w3.org/2001/10/xml-exc-c14n#'
            ],
            'http://www.w3.org/2000/09/xmldsig#sha1'
        );

        // Set the key and certificate
        sig.signingKey = privateKey;
        // noinspection JSUnusedGlobalSymbols
        sig.keyInfoProvider = {
            getKeyInfo: () => `
            <X509Data>
              <X509Certificate>${certificate.replace(/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\n/g, '')}</X509Certificate>
            </X509Data>`,
        };

        // Compute the signature
        sig.computeSignature(assertion, {
            location: {
                reference: "//*[local-name(.)='Issuer' and ancestor::*[local-name(.)='Assertion']]",
                action: 'after',
            },
            prefix: '',
        });

        // Get the signed assertion
        const signedAssertion = sig.getSignedXml();

        // Build the complete SAML Response
        const samlResponse = `<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                        ID="${responseID}" Version="2.0" IssueInstant="${issueInstant}"
                        Destination="${recipient}">
          <saml:Issuer xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">${issuer}</saml:Issuer>
          <samlp:Status>
            <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
          </samlp:Status>
          ${signedAssertion}
        </samlp:Response>`;

        // Base64 encode the response
        const base64Response = Buffer.from(samlResponse, 'utf-8').toString('base64');

        // Construct the HTML form
        const htmlForm = `<form method="post" action="${recipient}">
          <input type="hidden" name="SAMLResponse" value="${base64Response}" />
          <input type="submit" value="Submit" hidden="hidden"/>
        </form>
        <script type="text/javascript">
          document.forms[0].submit();
        </script>`;

        // Return the response as JSON
        return {
            statusCode: 200,
            headers: {'Content-Type': 'text/html'},
            body: htmlForm,
        };

    } catch (error) {
        // Handle errors and return a 500 status
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: "An error occurred.",
                error: error.message,
            }),
        };
    }
};

// Function to generate a unique ID
function generateUniqueID() {
    return '_' + crypto.randomBytes(10).toString('hex');
}

// Function to get current time in ISO format with milliseconds
function getCurrentTime() {
    return new Date().toISOString();
}
