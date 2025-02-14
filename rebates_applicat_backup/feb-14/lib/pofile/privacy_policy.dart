import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '1. General\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              '1.1  This Privacy Policy (“Privacy Policy”) applies to all Personal Data collected by Beyond Solar Pty Ltd (ACN 604966403) and its associated entities (collectively referred to as “Beyond Solar,” “we,” “our,” or “us”). This Privacy Policy does not apply to websites operated by Beyond Solar that do not link to this Privacy Policy.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
            TextSpan(
              text:
              '1.2  Beyond Solar is committed to complying with applicable Australian Data Protection Laws. BY ACCESSING AND USING OUR SERVICES OR ENGAGING IN COMMUNICATIONS WITH US, YOU AGREE TO THE PROCESSING OF YOUR PERSONAL DATA AS DESCRIBED IN THIS PRIVACY POLICY AND TO BE BOUND BY ITS TERMS.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
            TextSpan(
              text:
              ' •	If you are an Australian individual, the Privacy Act 1988 (as amended, the “AU Privacy Act”) and the Australian Privacy Principles (“APP”) apply to Personal Data about you.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'ShadowsIntoLight'),
            ),
            TextSpan(
              text:
              '1.3 This Privacy Policy explains how we collect, use, share, and protect your Personal Data and what controls you have over our use of it. Please read this Privacy Policy carefully. If you do not agree with these terms, please do not use our Services.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '2. Definitions\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              '2.1 In this Privacy Policy:\n\n',
              style: TextStyle(fontSize: 16),
            ),
            TextSpan(
              text:
              '•	Account means an account you need to register on our websites or with our representatives to place orders or access certain portions of our Services.\n\n•	Data Protection Laws means laws designed to protect your Personal Data and privacy, specifically under the AU Privacy Act.\n\n•	Personal Data means information that constitutes “personal data,” “personal information,” or similar, as governed by the AU Privacy Act.\n\n•	Services refers to services provided by Beyond Solar, including the promotion, ordering, delivery, and provision of renewable energy products and solutions.\n\n•	Websites refers to websites and platforms operated by Beyond Solar, including any Beyond Solar website that links to this Privacy Policy.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '3. Types of Personal Data We Collect\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,fontFamily: 'Serif'
              ),
            ),
            TextSpan(
              text:
              'We may collect, use, store, and transfer various types of Personal Data, including:\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
            TextSpan(
              text:
              '•	Identity Data: name, address, gender, and date of birth.\n\n•	Contact Data: billing address, email address, and phone number.\n\n•	Financial Data: bank account and payment card details.\n\n•	Technical Data: IP address, login data, browser type, access times, and usage data.\n\n•	Usage Data: information about your usage of our Services, including information from cookies.\n\n•	Marketing and Communications Data: preferences for receiving marketing communications and engagement details.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '4. How We Collect Personal Data\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'Personal Data is collected through:\n\n',
              style: TextStyle(fontSize: 16),
            ),
            TextSpan(
              text:
              '•	Direct Interactions: When you provide information by completing forms, communicating with us, or using our Services.\n\n•	Automated Means: Data collected automatically when you interact with our websites or Services (e.g., cookies).\n\n•	Third Parties and Public Sources: Data from publicly available sources, third-party service providers, or business partners.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '5. How We Store and Protect Personal Data\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
            ),
            TextSpan(
              text:
              'We take reasonable steps to protect your Personal Data, including:\n\n',
              style: TextStyle(fontSize: 16),
            ),
            TextSpan(
              text:
              '	•	Securing electronic records and protecting them within our secure network.\n\n•	Implementing physical security for paper records.\n\n•	Using third-party vendors who comply with Data Protection Laws.\n\n•	De-identifying or destroying Personal Data when it is no longer necessary for the purpose for which it was collected.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
            TextSpan(
              text:
              '	5.4 We will notify you of any data security breaches as required by Australian Data Protection Laws.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '6. How We Use Your Personal Data\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'Beyond Solar may collect, hold, use, and disclose your Personal Data to:\n\n',
              style: TextStyle(fontSize: 16),
            ),
            TextSpan(
              text:
              '	•	Fulfill the purposes for which it was disclosed or collected.\n\n•	Provide, support, and improve our Services.\n\n•	Respond to inquiries and requests.\n\n•	Send marketing and promotional information (with your consent).\n\n•	Comply with legal obligations and protect against harm or fraud.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '7. How We May Share or Disclose Personal Data\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'We may share your Personal Data with third parties, including:\n\n',
              style: TextStyle(fontSize: 16),
            ),
            TextSpan(
              text:
              '•	Within Beyond Solar and its affiliates.\n\n•	Contractors and service providers who assist us in delivering our Services.\n\n•	To comply with legal obligations or protect against harm, fraud, or other illegal activities.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '8. Australia\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'In Australia, our legal basis for processing Personal Data is your informed consent. By submitting Personal Data, you acknowledge granting consent to Beyond Solar.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '9. Direct Marketing\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'We will only send direct marketing communications about our Services with your consent. You may opt-out by contacting us or using the unsubscribe link provided in our communications. Our practices comply with anti-spam laws, including Australia’s Spam Act 2003.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '10. Unsolicited Informationn\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'If you provide unsolicited Personal Data, we will only retain it if it is reasonably necessary and you have expressly consented. Otherwise, we will destroy the unsolicited information.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '11. Children’s Privacy\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'Our Services are not intended for persons under 18. We do not knowingly collect Personal Data from children. If you are a parent or guardian and believe your child has provided us with Personal Data, please contact us.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '12. Third-party Sites\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'Our websites may link to third-party websites. We are not responsible for the privacy practices of these websites. We encourage you to review the privacy policies of any third-party sites you visit.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '13. Data Retention\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'We will only retain your Personal Data for as long as reasonably necessary to fulfill the purposes for which it was collected, and for any legal or regulatory requirements.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '14. Changes to This Privacy Policy\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'We may modify or update this Privacy Policy periodically. The latest version will apply to all your Personal Data held by us.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '15. Your Privacy Choices\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text:
              'Under the AU Privacy Act, you may have certain rights, including the right to access, correct, or delete your Personal Data. Requests should be submitted via the contact information below.\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '16. How to Contact Us\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
            ),
            TextSpan(
              text:
              'If you have any questions or concerns about this Privacy Policy or would like to exercise your rights, please contact us at:\n\n',
              style: TextStyle(fontSize: 16,fontFamily: 'Serif'),
            ),
            WidgetSpan(
              child: Center( // Centering the whole column
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Beyond Solar Pty Ltd',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red,fontFamily: 'ShadowsIntoLight'),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _launchEmail('Privacy.au@beyondsolar.com.au'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Privacy.au@beyondsolar.com.au',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              decoration: TextDecoration.underline
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _launchMap(),  // Navigate to map on click
                      child: Text(
                        '2/79 Williamson Rd, Ingleburn\nNSW 2565, Australia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline, // Add underline to indicate it's clickable
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _launchPhone('1300237684'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '1300237684',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          const SizedBox(height: 16),
      ],
      ),
      ),
    ),
    );
  }
  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $email';
    }
  }
  void _launchMap() async {
    String fullAddress = '2/79 Williamson Rd, Ingleburn NSW 2565, Australia'.replaceAll('\n', ', ');
    launch(
        "https://www.google.com/maps/search/?api=1&query=$fullAddress");
  }
}
