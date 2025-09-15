// Lightweight local learning resources to augment Firestore content.
// Each entry mirrors the fields expected by Guide.fromMap.

final List<Map<String, dynamic>> kLocalLearningResources = [
  {
    'id': 'local-sba-business-plan',
    'title': 'How to Write a Business Plan',
    'summary': 'Step-by-step SBA guide to writing a business plan.',
    'tags': ['Planning', 'Business Plan', 'SBA'],
    'url':
        'https://www.sba.gov/business-guide/plan-your-business/write-your-business-plan',
    'coverImage': 'https://www.profitableventure.com/wp-content/uploads/2023/02/Write-Business-Plan.jpg',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 7,
  },
  {
    'id': 'local-score-mentoring',
    'title': 'Free Business Mentoring & Education',
    'summary': 'Get matched with mentors and access business templates.',
    'tags': ['Mentoring', 'Templates', 'SCORE'],
    'url': 'https://www.score.org/',
    'category': 'Article',
    'author': 'SCORE',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 96,
  },
  {
    'id': 'local-irs-apply-ein',
    'title': 'Apply for an Employer Identification Number (EIN)',
    'summary': 'Official IRS page to apply for an EIN for your business.',
    'tags': ['Legal', 'Tax', 'US'],
    'url':
        'https://www.irs.gov/businesses/small-businesses-self-employed/apply-for-an-employer-identification-number-ein-online',
    'category': 'Article',
    'author': 'IRS',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 100,
  },
  {
    'id': 'local-quickbooks-accounting-basics',
    'title': 'Small Business Accounting 101',
    'summary':
        'Learn bookkeeping basics, financial statements, and best practices.',
    'tags': ['Accounting', 'Finance'],
    'url': 'https://quickbooks.intuit.com/r/bookkeeping/what-is-accounting/',
    'category': 'Article',
    'author': 'Intuit QuickBooks',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 101,
  },
  {
    'id': 'local-hubspot-crm-basics',
    'title': 'What is a CRM? The Complete Guide',
    'summary':
        'How CRMs help manage sales pipelines and customer relationships.',
    'tags': ['Sales', 'CRM'],
    'url': 'https://blog.hubspot.com/sales/what-is-a-crm',
    'category': 'Article',
    'author': 'HubSpot',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 102,
  },
  {
    'id': 'local-zendesk-customer-service',
    'title': 'Customer Service 101: Fundamentals & Best Practices',
    'summary': 'Deliver great support to keep customers happy and loyal.',
    'tags': ['Operations', 'Customer Service'],
    'url': 'https://www.zendesk.com/blog/customer-service-101/',
    'category': 'Article',
    'author': 'Zendesk',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 103,
  },
  {
    'id': 'local-govph-dti-business-name',
    'title': 'Register a Business Name (DTI Philippines)',
    'summary': 'Official guide to register a business name with DTI.',
    'tags': ['Legal', 'Registration', 'PH'],
    'url': 'https://bnrs.dti.gov.ph/',
    'category': 'Article',
    'author': 'DTI Philippines',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 104,
  },
  {
    'id': 'local-bir-ph-new-business',
    'title': 'BIR Registration for New Business (Philippines)',
    'summary': 'How to register with the Bureau of Internal Revenue.',
    'tags': ['Tax', 'Legal', 'PH'],
    'url':
        'https://www.bir.gov.ph/index.php/registration-requirements/primary-registration/application-for-registration.html',
    'category': 'Article',
    'author': 'BIR Philippines',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 105,
  },
  {
    'id': 'local-cdc-food-safety',
    'title': 'Food Safety Basics for Small Businesses',
    'summary': 'Key practices to keep customers safe if selling food.',
    'tags': ['Operations', 'Compliance', 'Food'],
    'url': 'https://www.cdc.gov/foodsafety/index.html',
    'category': 'Article',
    'author': 'CDC',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 106,
  },
  {
    'id': 'local-yt-lean-canvas',
    'title': 'Lean Canvas Explained in 15 Minutes',
    'summary': 'A quick overview of the Lean Canvas framework.',
    'tags': ['Planning', 'Video'],
    'videoUrl': 'https://www.youtube.com/watch?v=GgN8CGcT5c8',
    'category': 'Video',
    'author': 'LeanStack (YouTube)',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 107,
  },
  {
    'id': 'local-yt-mvp-product',
    'title': 'How to Build an MVP (Minimum Viable Product)',
    'summary': 'Strategies to validate quickly with minimal investment.',
    'tags': ['Product', 'Validation', 'Video'],
    'videoUrl': 'https://www.youtube.com/watch?v=1hHMwLxN6EM',
    'category': 'Video',
    'author': 'Slidebean (YouTube)',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 108,
  },
  {
    'id': 'local-sba-fund-business',
    'title': 'Fund Your Business',
    'summary': 'Explore funding options like loans, grants, and investors.',
    'tags': ['Funding', 'Finance', 'SBA'],
    'url':
        'https://www.sba.gov/business-guide/plan-your-business/fund-your-business',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 25,
  },
  {
    'id': 'local-sba-marketing-plan',
    'title': 'Write Your Marketing Plan',
    'summary': 'Define your marketing strategy and channels.',
    'tags': ['Marketing', 'SBA', 'Go-To-Market'],
    'url':
        'https://www.sba.gov/business-guide/manage-your-business/marketing-sales/write-your-marketing-plan',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 27,
  },
  {
    'id': 'local-bplans-sample-plans',
    'title': 'Sample Business Plans (Bplans)',
    'summary': 'Browse hundreds of sample business plans by industry.',
    'tags': ['Business Plan', 'Templates'],
    'url': 'https://www.bplans.com/sample-business-plans/',
    'category': 'Article',
    'author': 'Bplans',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 60,
  },
  {
    'id': 'local-shopify-pricing-strategies',
    'title': 'Pricing Strategies: How to Price Your Products',
    'summary': 'Common pricing models and how to choose yours.',
    'tags': ['Pricing', 'Revenue'],
    'url': 'https://www.shopify.com/blog/pricing-strategies',
    'category': 'Article',
    'author': 'Shopify',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 55,
  },
  {
    'id': 'local-stripe-atlas-legal',
    'title': 'Startup Legal Basics (Stripe Atlas Guides)',
    'summary': 'Key legal concepts for startups and founders.',
    'tags': ['Legal', 'Incorporation', 'Compliance'],
    'url': 'https://stripe.com/atlas/guides',
    'category': 'Article',
    'author': 'Stripe Atlas',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 65,
  },
  {
    'id': 'local-govuk-set-up-business',
    'title': 'Set up a business (UK)',
    'summary': 'Official guidance to register and run a business in the UK.',
    'tags': ['Legal', 'Registration', 'UK'],
    'url': 'https://www.gov.uk/set-up-business',
    'category': 'Article',
    'author': 'GOV.UK',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 70,
  },
  {
    'id': 'local-investopedia-gross-margin',
    'title': 'Gross Margin vs. Markup: What’s the Difference?',
    'summary': 'Understand core profitability metrics and how to use them.',
    'tags': ['Finance', 'Margins', 'COGS'],
    'url':
        'https://www.investopedia.com/ask/answers/071314/what-difference-between-margin-and-markup.asp',
    'category': 'Article',
    'author': 'Investopedia',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 75,
  },
  {
    'id': 'local-mailchimp-marketing-plan',
    'title': 'How to Create a Marketing Plan (with Template)',
    'summary': 'Practical guide and template for building a marketing plan.',
    'tags': ['Marketing', 'Template', 'Go-To-Market'],
    'url': 'https://mailchimp.com/resources/marketing-plan/',
    'category': 'Article',
    'author': 'Mailchimp',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 80,
  },
  {
    'id': 'local-hubspot-branding-guide',
    'title': 'Branding 101: How to Build a Brand',
    'summary': 'What a brand is and how to create one that stands out.',
    'tags': ['Branding', 'Marketing'],
    'url': 'https://blog.hubspot.com/marketing/what-is-branding',
    'category': 'Article',
    'author': 'HubSpot',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 85,
  },
  {
    'id': 'local-think-with-google-strategy',
    'title': 'Marketing Strategy Insights (Think with Google)',
    'summary': 'Trends and insights to shape your marketing strategy.',
    'tags': ['Marketing', 'Insights'],
    'url': 'https://www.thinkwithgoogle.com/marketing-strategies/',
    'category': 'Article',
    'author': 'Think with Google',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 90,
  },
  {
    'id': 'local-yc-startup-lecture-1',
    'title': 'How to Start a Startup — Lecture 1 (YC)',
    'summary': 'Introduction to starting startups by Y Combinator.',
    'tags': ['Startup', 'Video'],
    'videoUrl': 'https://www.youtube.com/watch?v=ZoqgAy3h4OM',
    'category': 'Video',
    'author': 'Y Combinator',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 95,
  },
  {
    'id': 'local-sba-market-research',
    'title': 'Market Research and Competitive Analysis',
    'summary': 'Learn how to research your market and analyze competitors.',
    'tags': ['Market Research', 'SBA', 'Validation'],
    'url':
        'https://www.sba.gov/business-guide/plan-your-business/market-research-competitive-analysis',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 10,
  },
  {
    'id': 'local-sba-startup-costs',
    'title': 'Calculate Your Startup Costs',
    'summary': 'Estimate the money you need to start your business.',
    'tags': ['Finance', 'Costs', 'SBA'],
    'url':
        'https://www.sba.gov/business-guide/plan-your-business/calculate-your-startup-costs',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 14,
  },
  {
    'id': 'local-sba-business-structure',
    'title': 'Choose a Business Structure',
    'summary': 'Compare LLCs, sole proprietorships, corporations, and more.',
    'tags': ['Legal', 'Structures', 'SBA'],
    'url':
        'https://www.sba.gov/business-guide/launch-your-business/choose-business-structure',
    'category': 'Article',
    'author': 'U.S. Small Business Administration',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 21,
  },
  {
    'id': 'local-shopify-start-business',
    'title': 'How to Start a Business in 8 Steps',
    'summary': 'A beginner-friendly walkthrough to launch a business.',
    'tags': ['Getting Started', 'Operations'],
    'url': 'https://www.shopify.com/blog/how-to-start-a-business',
    'category': 'Article',
    'author': 'Shopify',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 30,
  },
  {
    'id': 'local-shopify-market-research',
    'title': 'How to Do Market Research',
    'summary': 'Practical methods for market research with examples.',
    'tags': ['Market Research', 'Validation'],
    'url': 'https://www.shopify.com/blog/market-research',
    'category': 'Article',
    'author': 'Shopify',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 35,
  },
  {
    'id': 'local-hubspot-business-plan',
    'title': 'What Is a Business Plan? (+ How to Write One)',
    'summary': 'A modern guide with templates to create business plans.',
    'tags': ['Business Plan', 'Templates'],
    'url': 'https://blog.hubspot.com/marketing/business-plan',
    'category': 'Article',
    'author': 'HubSpot',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 40,
  },
  {
    'id': 'local-hubspot-buyer-persona',
    'title': 'The Marketer’s Guide to Buyer Persona Research',
    'summary': 'How to research and build accurate customer personas.',
    'tags': ['Persona', 'Marketing'],
    'url': 'https://blog.hubspot.com/marketing/buyer-persona-research',
    'category': 'Article',
    'author': 'HubSpot',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 45,
  },
  {
    'id': 'local-kauffman-business-plan-video',
    'title': 'Writing a Business Plan (Kauffman Founders School)',
    'summary': 'Video lesson on structuring an effective plan.',
    'tags': ['Business Plan', 'Video'],
    'videoUrl': 'https://www.youtube.com/watch?v=Fqch5OrUPvA',
    'category': 'Video',
    'author': 'Kauffman Founders School',
    'createdAt':
        DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 50,
  },
];
