import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsOfUsePage extends StatefulWidget {
  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms and Conditions',
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
                      text: '1. Background\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                          '(a) These Terms of Use (Terms) constitute a legal agreement between you (User, you or your) and Beyond Solar Pty Ltd (ACN 604966403) (Beyond Solar, us or we) for:\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                          '•	the installer and service management features available on the backend system called Worksheets (Portal); and\n\n•	the application known as Beyond Solar Toolkit, operated by us (App), together, the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'ShadowsIntoLight'),
                    ),
                    TextSpan(
                      text:
                          ' (b) These Terms also apply to all upgrades we make to the Platforms from time to time.\n\n',
                      style: TextStyle(
                          fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '2. Users\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      '2.1 Types of Users\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      '(a) Your use of the Platforms will depend on whether:\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '•	you are an installer engaged to perform installations or services via the Platforms (Installer);\n\n•	you are a designer engaged to design installations or services via the Platforms (Designer); or\n\n•	you are an electrician engaged to perform installations or certifications via the Platforms (Electrician).\n\n',
                      style: TextStyle(
                          fontSize: 16, fontFamily: 'ShadowsIntoLight'),
                    ),
                    TextSpan(
                      text:
                      '(b) For the purpose of these Terms, Installers, Designers, and Electricians will collectively be referred to as Users.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '2.2 Installation Information\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)

                    ),
                    TextSpan(
                      text:
                      'Each User must:\n\n',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text:
                      '•	provide relevant Installation Information as set out in the Platforms after completing each installation;\n\n•	provide additional information requested by Beyond Solar; and\n\n•	ensure all provided information is accurate, up-to-date, and complete.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '3. Term \n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'These Terms commence on the date you accept them or begin using the Platforms and continue until:\n\n',
                      style: TextStyle(fontSize: 16),
                    ),
                    TextSpan(
                      text:
                      '•	you stop using the Platforms; or\n\n•	the Terms are terminated by either party as per clause 10.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '4. Grant of Licence \n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      '4.1 Licence\n\n',
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar grants you a royalty-free, revocable, non-exclusive, non-transferable licence to use the Platforms for the Term, subject to compliance with these Terms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '4.2 Your Obligations\n\n',
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'You agree to:\n\n•	use the Platforms only for their intended purposes;\n\n•	report any issues with the Platforms;\n\n•	keep account information current and secure; and\n\n•	comply with these Terms, applicable laws, and any directions issued by us regarding your use of the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '4.3 Upgrades, Updates, etc.\n\n',
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar will notify you of significant upgrades to the Platforms. We are not obligated to support older versions of the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '5. Additional Conditions of Use\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      '5.1 Prohibitions on Use of Platforms\n\n',
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'You must not:\n\n•	transfer, sell, or sublicense the Platforms;\n\n•	reverse-engineer or make derivative works of the Platforms;\n\n•	interfere with other Users’ access to or use of the Platforms; or\n\n•	submit information not contemplated by these Terms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '5.2 Beyond Solar’s Rights\n\n',
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar may:\n\n•	upgrade the Platforms at any time;\n\n•	perform maintenance on the Platforms, with advance notice where practical; and\n\n•	discontinue the Platforms or any component with reasonable prior notice on our website.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '6. Confidential Information\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'You must keep Beyond Solar’s Confidential Information secure and only disclose it to those who need to know, ensuring they are bound by confidentiality obligations as strict as these Terms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '7. Intellectual Property Rights\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar retains all Intellectual Property Rights in the Platforms. You may not use any Beyond Solar content outside of the permitted use of the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '8. Your Indemnity\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'You agree to indemnify Beyond Solar and its personnel from claims, losses, or damages arising from your breach of these Terms or misuse of the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '9. Privacy\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'You must ensure appropriate consents and notices for lawful transfer of any personal information to Beyond Solar. Our use of personal information is governed by our Privacy Policy, which is available on our website.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '10. Termination and Suspension\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'Either party may terminate these Terms with notice. Beyond Solar may suspend or terminate access if you breach key obligations under these Terms. Upon termination, you must stop using the Platforms and comply with any return or destruction requests for Confidential Information.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '11. Limitation of Liability\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'To the extent permitted by law, Beyond Solar disclaims all implied warranties and will not be liable for any loss caused by third-party utilities or services affecting the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '12. Force Majeure\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar is not liable for delays caused by events beyond its control (Force Majeure Events). The affected party must notify the other party and take reasonable steps to mitigate the effects of the Force Majeure Event.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '13. General\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, fontFamily: 'YesevaOne'
                      ),
                    ),
                    TextSpan(
                      text:
                      '13.1 Assignment\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'You may not assign rights or obligations under these Terms without Beyond Solar’s consent. Beyond Solar may assign its rights and obligations without your consent.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '13.2 Amendments\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'Beyond Solar may vary these Terms with notice. If changes affect you materially, you may terminate without penalty.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '13.3 Compliance with Laws\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'Each party must comply with applicable laws.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '13.4 Governing Law\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'These Terms are governed by the laws of New South Wales, Australia, and the parties submit to the exclusive jurisdiction of its courts.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text:
                      '13.5 Entire Agreement\n\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                      'These Terms represent the entire agreement and supersede any prior agreements or understandings regarding the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '14. Definitions\n\n',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        fontFamily: 'YesevaOne',
                      ),
                    ),
                    TextSpan(
                      text: '• Australian Consumer Law ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means Schedule 2, Competition and Consumer Act 2010 (Cth).\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Confidential Information ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means non-public information disclosed by a party that is marked as confidential or which should reasonably be understood as confidential, including trade secrets, financial information, and proprietary business information.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Consequential Loss ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means indirect losses, including lost profits, lost revenue, business interruption, or reputational harm.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Data Protection Legislation ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means:\n  • the Privacy Act 1988 (Cth) and associated rules and codes;\n  • the Australian Privacy Principles (APPs); and\n  • any other applicable laws governing the processing of personal information.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Documentation ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to technical specifications and usage materials provided by Beyond Solar that specify the functionalities of the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Force Majeure Event ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'includes events beyond reasonable control, such as natural disasters, industrial actions, pandemics, or government restrictions.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Insolvency Event ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'includes events like bankruptcy, liquidation, or inability to pay debts as they become due.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Installation Data ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to all information provided by you or generated in connection with the Platforms, including personal information, related to the installation or use of Beyond Solar products.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Installation Information ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'includes data provided via the Platforms in relation to installation activities, as required for the purposes of these Terms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Intellectual Property Rights ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means rights associated with intellectual property, such as copyrights, patents, trademarks, and trade secrets.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Personnel ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'includes a party’s directors, officers, employees, agents, and contractors.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Platforms ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'collectively refers to the Portal and App as governed by these Terms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Privacy Policy ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to the privacy policy available on Beyond Solar’s website.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Term ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'is defined in clause 3.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Third Party Agreement ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to terms issued by third-party suppliers for the use of any third-party applications associated with the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Third Party App ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'means any application provided by a third party that integrates with the Platforms but is not controlled by Beyond Solar.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Upgrades ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to any updates, upgrades, bug fixes, or enhancements made to the Platforms.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                    TextSpan(
                      text: '• Website ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Teko'),
                    ),
                    TextSpan(
                      text: 'refers to Beyond Solar’s website and associated online services.\n\n',
                      style: TextStyle(fontSize: 16, fontFamily: 'Serif'),
                    ),
                  ],
                ),
              ),
              Center( // Centering the whole column
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
                      onTap: () => _launchMap(),
                      child: Text(
                        '2/79 Williamson Rd, Ingleburn\nNSW 2565, Australia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
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
