module Avalara
  class BagFeeService
    # Updated 04/30/2022 according to https://minibar.atlassian.net/browse/TECH-5581?focusedCommentId=45028
    FEES = {
      "CA": {
        "STATE_WIDE": 0.10
      },
      "MA": {
        "CAMBRIDGE": 0.10,
        "NEWTON": 0.10
      },
      "NY": {
        "BEDFORD": 0.10,
        "MANHATTAN": 0.5,
        "BROOKLYN": 0.5,
        "BRONX": 0.5,
        "QUEENS": 0.5,
        "NYC": 0.5,
        "NEW CASTLE": 0.10,
        "LONG BEACH": 0.5,
        "RIVERHEAD": 0.5,
        "BABYLON": 0.5,
        "BROOKHAVEN": 0.5,
        "EAST HAMPTON": 0.5,
        "HUNTINGTON": 0.5,
        "ISLIP": 0.5,
        "SHELTER ISLAND": 0.5,
        "SMITHTOWN": 0.5,
        "SOUTHAMPTON": 0.5,
        "SOUTHOLD": 0.5,
        "SEA CLIFF": 0.5,
        "LEWISBORO": 0.15
      },
      "NJ": {
        "KEARNY": 0.10,
        "TRENTON": 0.10,
        "BERKELEY HEIGHTS": 0.10,
        "MORRISTOWN": 0.10,
        "COLLINGSWOOD": 0.10,
        "WOODLAND PARK": 0.10,
        "HAWORTH": 0.10,
        "MADISON": 0.10,
        "CHATHAM TOWNSHIP": 0.10,
        "SECAUCUS": 0.10,
        "SOUTH ORANGE": 0.5,
        "SEABRIGHT": 0.10,
        "MONTCLAIR": 0.10,
        "PARSIPPANY": 0.10,
        "HIGHLAND PARK": 0.10,
        "MAPLEWOOD": 0.5,
        "HOBOKEN": 0.25,
        "SOMERS POINT": 0.5,
        "VENTNOR CITY": 0.5,
        "TEANECK": 0.5,
        "LONGPORT": 0.10
      },
      "CT": {
        "MADISON": 0.10,
        "DARIEN": 0.10,
        "BRANDORD": 0.10,
        "WINDHAM": 0.10,
        "MIDDLETOWN": 0.10,
        "NEW CANAAN": 0.10,
        "NEW BRITAIN": 0.10,
        "NORWALK": 0.10
      },
      "MD": {
        "BALTIMORE": 0.5,
        "COLUMBIA": 0.5,
        "ELLICOTT CITY": 0.5,
        "ELKRIDGE": 0.5,
        "FULTON": 0.5,
        "NORTH LAUREL": 0.5,
        "WOODSTOCK": 0.5,
        "HIGHLAND": 0.5,
        "ROCKVILLE": 0.5,
        "SILVER SPRING": 0.5,
        "BETHESDA": 0.5,
        "GAITHERSBURG": 0.5,
        "ASHTON": 0.5,
        "BARNSVILLE": 0.5,
        "BEALLSVILLE": 0.5,
        "BOYDS": 0.5,
        "BRINKLOW": 0.5,
        "BROOKEVILLE": 0.5,
        "BURTONSVILLE": 0.5,
        "CHEVY CHASE": 0.5,
        "KENSINGTON": 0.5,
        "LOYTONSVILLE": 0.5,
        "POOLESVILLE": 0.5,
        "TAKOMA PARK": 0.5,
        "WASHINGTON GROVE": 0.5
      },
      "VA": {
        "LEESBURG": 0.5,
        "MIDDLEBURG": 0.5,
        "PURCELLVILLE": 0.5,
        "HILLSBORO": 0.5,
        "ASHBURN": 0.5,
        "ROUND HILL": 0.5,
        "STERLING": 0.5,
        "HAMILTON": 0.5,
        "BLUEMONT": 0.5,
        "LOVETTSVILLE": 0.5,
        "LUCKETTS": 0.5,
        "WATERFORD": 0.5,
        "FALLS CHURCH": 0.5,
        "ROANOKE": 0.5,
        "ARLINGTON": 0.5,
        "ALEXANDRIA": 0.5,
        "ANNANDALE": 0.5,
        "BURKE": 0.5,
        "CENTREVILLE": 0.5,
        "CHANTILLY": 0.5,
        "CLIFTON": 0.5,
        "DUNN LORING": 0.5,
        "FAIRFAX": 0.5,
        "FORT BELVOIR": 0.5,
        "GREAT FALLS": 0.5,
        "HERNDON": 0.5,
        "LORTON": 0.5,
        "MCLEAN": 0.5,
        "OAKTON": 0.5,
        "RESTON": 0.5,
        "SPRINGFIELD": 0.5,
        "VIENNA": 0.5,
        "FREDERICKSBURG": 0.5
      },
      "OH": {
        "CINCINNATI": 0.5
      },
      "IL": {
        "EDWARDSBILLE": 0.10,
        "WOODSTOCK": 0.10,
        "OAK PARK": 0.10,
        "CHICAGO": 0.7
      },
      "MN": {
        "MINNEAPOLIS": 0.5,
        "DULUTH": 0.5
      },
      "CO": {
        "FORT COLLINS": 0.12,
        "LOUISVILLE": 0.25,
        "FRISCO": 0.25,
        "BRECKENRIDGE": 0.10,
        "DENVER": 0.10,
        "WINTER PARK": 0.20,
        "FRASER": 0.20,
        "AVON": 0.10,
        "NEDERLAND": 0.10,
        "BOULDER": 0.10,
        "CARBONDALE": 0.20,
        "ASPEN": 0.20,
        "TELLURIDE": 0.10
      },
      "WA": {
        "SEATTLE": 0.5,
        "OLYMPIA": 0.5,
        "KIRKLAND": 0.5
      },
      "OR": {
        "CORVALLIS": 0.5,
        "EUGENE": 0.5,
        "ASHLAND": 0.10,
        "SALEM": 0.5,
        "NEWPORT": 0.5,
        "LAKE OSWEGO": 0.10
      },
      "MI": {
        "ANN ARBOR": 0.10,
        "BRIDGEWATER TOWNSHIP": 0.10,
        "CHELSEA": 0.10,
        "MANCHESTER": 0.10,
        "SALEM": 0.10,
        "SALINE": 0.10,
        "WHITTAKER": 0.10,
        "WILLIS": 0.10,
        "YPSILANTI": 0.10
      }
    }.freeze

    def initialize(shipment, fallback_address = nil)
      @shipment = shipment
      @fallback_address = fallback_address
    end

    def get_bag_fee
      return 0.0 unless bag_fee_applicable?

      address = Avalara::Helpers.get_taxable_address(@shipment, @fallback_address)
      state_abbr = address&.state&.abbreviation&.upcase&.to_sym
      city = address&.city&.upcase&.to_sym if address.respond_to?(:city)

      get_fee_amount(state_abbr, city)
    end

    private

    def bag_fee_applicable?
      return false if @shipment.bartender_shipment?
      return false if @shipment.digital?

      true
    end

    def get_fee_amount(state, city)
      state_fees = FEES[state]
      return 0.0 if state_fees.nil?

      state_wide_fee = state_fees['STATE_WIDE'.to_sym]
      return state_wide_fee unless state_wide_fee.nil?

      city_fee = state_fees[city]
      return city_fee unless city_fee.nil?

      0.0
    end
  end
end
