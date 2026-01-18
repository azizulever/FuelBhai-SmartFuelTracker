/**
 * Firebase Cloud Function for sending email verification codes
 * 
 * SETUP INSTRUCTIONS:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login to Firebase: firebase login
 * 3. Initialize functions: firebase init functions (select JavaScript/TypeScript)
 * 4. Install dependencies: cd functions && npm install
 * 5. Set SendGrid API key: firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
 * 6. Deploy: firebase deploy --only functions
 * 
 * SENDGRID SETUP:
 * 1. Sign up at https://sendgrid.com (free tier: 100 emails/day)
 * 2. Verify a sender email address
 * 3. Create an API key
 * 4. Use the API key in step 5 above
 */

const functions = require('firebase-functions');
const sgMail = require('@sendgrid/mail');

// Initialize SendGrid with API key from environment config
sgMail.setApiKey(functions.config().sendgrid.key);

exports.sendVerificationEmail = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  try {
    const { email, code, name } = req.body;

    // Validate input
    if (!email || !code || !name) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    // Email template
    const msg = {
      to: email,
      from: 'YOUR_VERIFIED_SENDER_EMAIL@example.com', // Replace with your verified sender email
      subject: 'FuelBhai - Email Verification Code',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Email Verification</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f8fafc;">
          <table role="presentation" style="width: 100%; border-collapse: collapse;">
            <tr>
              <td align="center" style="padding: 40px 0;">
                <table role="presentation" style="width: 600px; border-collapse: collapse; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                  
                  <!-- Header -->
                  <tr>
                    <td style="padding: 40px 40px 30px 40px; text-align: center; background: linear-gradient(135deg, #1E5EFF 0%, #3B82F6 100%); border-radius: 8px 8px 0 0;">
                      <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 700;">FuelBhai</h1>
                    </td>
                  </tr>
                  
                  <!-- Content -->
                  <tr>
                    <td style="padding: 40px;">
                      <h2 style="margin: 0 0 20px 0; color: #1f1f1f; font-size: 24px; font-weight: 600;">Hi ${name}!</h2>
                      <p style="margin: 0 0 20px 0; color: #6b7280; font-size: 16px; line-height: 1.5;">
                        Thank you for signing up with FuelBhai. To complete your registration, please verify your email address using the code below:
                      </p>
                      
                      <!-- Verification Code -->
                      <table role="presentation" style="width: 100%; margin: 30px 0;">
                        <tr>
                          <td align="center" style="background-color: #eff6ff; padding: 20px; border-radius: 8px;">
                            <div style="font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #2563eb; font-family: 'Courier New', monospace;">
                              ${code}
                            </div>
                          </td>
                        </tr>
                      </table>
                      
                      <p style="margin: 20px 0 0 0; color: #6b7280; font-size: 14px; line-height: 1.5;">
                        This code will expire in <strong>10 minutes</strong>.
                      </p>
                      
                      <p style="margin: 30px 0 0 0; color: #6b7280; font-size: 14px; line-height: 1.5;">
                        If you didn't request this code, please ignore this email.
                      </p>
                    </td>
                  </tr>
                  
                  <!-- Footer -->
                  <tr>
                    <td style="padding: 30px 40px; background-color: #f8fafc; border-radius: 0 0 8px 8px; text-align: center;">
                      <p style="margin: 0; color: #9ca3af; font-size: 12px;">
                        © 2026 FuelBhai. All rights reserved.
                      </p>
                    </td>
                  </tr>
                  
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
      `,
      text: `Hi ${name}!\n\nThank you for signing up with FuelBhai. Your verification code is: ${code}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this code, please ignore this email.\n\n© 2026 FuelBhai. All rights reserved.`,
    };

    // Send email
    await sgMail.send(msg);

    console.log(`Verification email sent to ${email}`);
    res.status(200).json({ success: true, message: 'Email sent successfully' });

  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({ 
      error: 'Failed to send email',
      details: error.message 
    });
  }
});
