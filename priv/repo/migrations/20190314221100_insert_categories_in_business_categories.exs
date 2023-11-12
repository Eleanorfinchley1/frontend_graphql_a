defmodule Repo.Migrations.InsertCategoriesInBusinessCategories do
  use Ecto.Migration

  def change do
    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Arts, crafts, and collectibles', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Baby', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Beauty and fragrances', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Books and magazines', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Business to business', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Clothing, accessories, and shoes', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Computers, accessories, and services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Education', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Electronics and telecom', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Entertainment and media', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Financial services and products', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Food retail and service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Gifts and flowers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Government', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Health and personal care', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Home and garden', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Nonprofit', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Pets and animals', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Religion and spirituality (for profit)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Services - other', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Sports and outdoors', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Toys and hobbies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Travel', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vehicle sales', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vehicle service and accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Antiques', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Art and craft supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Art dealers and galleries', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Camera and photographic supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Digital art', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Memorabilia', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Music store (instruments and sheet music)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Sewing, needlework, and fabrics', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Stamp and coin', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Stationary, printing and writing paper', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vintage and collectibles', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Clothing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Furniture', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Baby products (other)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Safety and health', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Bath and body', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Fragrances and perfumes', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Makeup and cosmetics', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Audio books', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Digital content', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Educational and textbooks', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Fiction and nonfiction', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Magazines', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Publishing and printing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Rare and used books', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Accounting', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Advertising', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Agricultural', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Architectural, engineering, and surveying services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Chemicals and allied products', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Commercial photography, art, and graphics', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Construction', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Consulting services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Educational services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Equipment rentals and leasing services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Equipment repair services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Hiring services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Industrial and manufacturing supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Mailing lists', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Marketing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Multi-level marketing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Office and commercial furniture', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Office supplies and equipment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Quick copy and reproduction services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Shipping and packing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Stenographic and secretarial support services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Wholesale', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Children''s clothing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Men''s clothing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Women''s clothing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Shoes', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Military and civil service uniforms', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Retail (fine jewelry and watches)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Wholesale (precious stones and metals)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Fashion jewelry', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Computer and data processing services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Desktops, laptops, and notebooks', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('eCommerce services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Maintenance and repair services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Monitors and projectors', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Networking', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Online gaming', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Parts and accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Peripherals', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Software', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Training services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Web hosting and design', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Business and secretarial schools', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Child daycare services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Colleges and universities', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Dance halls, studios, and schools', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Elementary and secondary schools', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vocational and trade schools', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Cameras, camcorders, and equipment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Cell phones, PDAs, and pagers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('General electronic accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Home audio', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Home electronics', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Security and surveillance', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Telecommunication equipment and sales', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Telecommunication services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Telephone cards', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Movie tickets', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Movies (DVDs, videotapes)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Music (CDs, cassettes and albums)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Cable, satellite, and other pay TV and radio', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Concert tickets', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Theater tickets', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Toys and games', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Slot machines', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Entertainers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Gambling', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Online games', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Video games and systems', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Collection agency', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Commodities and futures exchange', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Consumer credit reporting agencies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Debt counseling service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Credit union', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Currency dealer and currency exchange', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Escrow', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Finance company', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Financial and investment advice', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Insurance (auto and home)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Insurance (life and annuity)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Investments (general)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Money service business', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Mortgage brokers or dealers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Online gaming currency', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Paycheck lender or cash advance', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Prepaid and stored value cards', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Real estate agent', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Remittance', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Rental property management', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Security brokers and dealers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Wire transfer and money order', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Alcoholic beverages', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Catering services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Coffee and tea', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Gourmet foods', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Specialty and miscellaneous food stores', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Restaurant', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Tobacco', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vitamins and supplements', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Florist', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Gift, card, novelty, and souvenir shops', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Nursery plants and flowers', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Party supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Government services (not elsewhere classified)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Drugstore (excluding prescription drugs)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Drugstore (including prescription drugs)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Dental care', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Medical care', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Medical equipment and supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Vision care', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Appliances', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Bed and bath', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Construction material', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Drapery, window covering, and upholstery', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Exterminating and disinfecting services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Fireplace, and fireplace screens', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Garden supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Glass, paint, and wallpaper', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Hardware and tools', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Home decor', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Housewares', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Kitchenware', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Landscaping', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Rugs and carpets', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Security and surveillance equipment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Swimming pools and spas', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Charity', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Political', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Religious', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Other', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Personal', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Educational', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Medication and supplements', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Pet shops, pet food, and supplies', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Specialty or rare pets', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Veterinary services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Membership services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Merchandise', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Services (not elsewhere classified)', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Department store', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Discount store', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Durable goods', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Non-durable goods', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Used and secondhand store', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Variety store', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Shopping services and buying clubs', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Career services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Carpentry', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Child care services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Cleaning and maintenance', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Commercial photography', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Computer network services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Counseling services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Courier services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Electrical and small appliance repair', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Entertainment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Equipment rental and leasing services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Event and wedding planning', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('General contractors', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Graphic and commercial design', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Health and beauty spas', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('IDs, licenses, and passports', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Importing and exporting', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Information retrieval services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Insurance - auto and home', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Insurance - life and annuity', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Landscaping and horticultural', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Legal services and attorneys', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Local delivery service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Lottery and contests', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Membership clubs and organizations', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Misc. publishing and printing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Moving and storage', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Online dating', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Photofinishing', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Photographic studios - portraits', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Protective and security services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Radio, television, and stereo repair', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Reupholstery and furniture repair', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Swimming pool services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Tailors and alterations', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Telecommunication service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Utilities', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Watch, clock, and jewelry repair', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Athletic shoes', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Bicycle shop, service, and repair', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Boating, sailing and accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Camping and outdoors', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Fan gear and memorabilia', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Firearm accessories', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Firearms', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Hunting', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Knives', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Martial arts weapons', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Sport games and toys', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Sporting equipment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Arts and crafts', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Hobby, toy, and game shops', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Music store - instruments and sheet music', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Stationary, printing, and writing paper', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Airline', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Auto rental', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Bus line', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Cruises', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Lodging and accommodations', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Luggage and leather goods', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Recreational services', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Sporting and recreation camps', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Taxicabs and limousines', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Timeshares', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Tours', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Trailer parks or campgrounds', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Transportation services - other', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Travel agency', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Auto dealer - new and used', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Auto dealer - used only', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Aviation', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Boat dealer', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Motorcycle dealer', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Recreational and utility trailer dealer', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Recreational vehicle dealer.Vintage and collectibles', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('New parts and supplies - motor vehicle', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Used parts - motor vehicle', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Audio and video', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Auto body repair and paint', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Auto service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Automotive tire supply and service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Boat rental and leases', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Car wash', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Motor home and recreational vehicle rental', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Tools and equipment', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Towing service', now(), now())"

    execute "INSERT INTO business_categories(category_name, created, updated) VALUES('Truck and utility trailer rental', now(), now())"
  end

  def down do
    execute "DELETE FROM business_categories"
  end
end
