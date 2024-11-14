// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract OnlineMarket {
    AggregatorV3Interface dataFeed;

    Platform public platform;

    struct Platform {
        address AddressPlatform; // ที่อยู่กระเป๋าเงินของ(แพลตฟอร์ม)
        uint256 created; // สร้างเมื่อ
        string name; // ชื่อแพลตฟอร์ม
        uint256 percent; // เปอร์เซ็นต์ที่หัก
    }

    struct Seller {
        address AddressSeller; // ที่อยู่กระเป๋าเงินของ(ผู้ขาย)
        uint256 created; // สร้างเมื่อ
        string name; // ชื่อสินค้า
        string tel; // เบอร์
    }

    struct Customer {
        address AddressCustomer; // ที่อยู่กระเป๋าเงินของ(ผู้ซื้อ)
        uint256 created; // สร้างเมื่อ
        string name; // ชื่อผู้ซื้อ
        bytes location; // ที่อยู่
        bytes tel; // เบอร์
    }

    struct Transport {
        address AddressTransport; // ที่อยู่กระเป๋าเงินของ(ขนส่ง)
        uint256 created; // สร้างเมื่อ
        string name; // ชื่อขนส่ง
        string tel; // เบอร์
        string transportType; // ประเภทการจัดส่ง
        string exporttype; // ประเภทการส่งออก
    }

    struct Product {
        uint256 itemID; // รหัสสินค้า
        uint256 created; // สร้างเมื่อ
        string name; // ชื่อสินค้า
        string detail; // รายละเอียดสินค้า
        string ptype; // ประเภทสินค้า
        uint256 price; // ราคาสินค้า
        uint256 weight; // น้ำหนักสินค้า
        uint256 width; // ความกว้างสินค้า
        uint256 length; // ความยาวสินค้า
        uint256 height; // ความสูงสินค้า
        uint256 inventory; // จำนวนสินค้า
        address AddressSeller; // ที่อยู่กระเป๋าเงินของผู้ขาย
    }

    struct Order {
        uint256 orderId; // รหัสคำสั่งซื้อ
        uint256 created; // สร้างเมื่อ
        uint256[] productIds; // รายการรหัสสินค้าที่สั่งซื้อ
        uint256 sum; // รวมค่าสินค้า+ค่าขนส่ง
        uint256 shippingCost; // ค่าขนส่ง
        bool status; // สถานะ Order ( true ดำเนินการ / false เกิดข้อผิดพลาดคืนเงืน)
        bool isDelivered; // สถานะการจัดส่ง ( true กำลังขนส่ง / false เกิดข้อผิดพลาดคืนเงิน)
        bool isReceived; // สถานะการรับสินค้า ( true ผู้รับได้รับสินค้า / false เกิดข้อผิดพลาดคืนเงิน)
        string noteDelivered; // หมายเหตุ:(ขนส่ง)
        string noteReceived; // หมายเหตุ:(ผู้รับ)
        address customerAddress; // ที่อยู่กระเป๋าเงินของลูกค้า
        address transportAddress; // ที่อยู่กระเป๋าเงินของขนส่ง
    }

    uint256 sellerCounter;
    uint256 productCounter;
    uint256 customerCounter;
    uint256 orderCounter;
    uint256 transportCounter;

    mapping(address => Seller) Sellers;
    mapping(address => Customer) Customers;
    mapping(address => Transport) Transports;
    mapping(uint256 => Product) Products;
    mapping(uint256 => Order) Orders;

    address[] listMoney; // รายการเงิน
    mapping(address => uint256) public MyMoney; // ตรวจสอบเงิน หากเป็น public กำหนดไว้เพื่อ Testing เปิดใช้งานจริง จะไม่เป็น public

    constructor(string memory _name, uint256 _percent) {
        platform.AddressPlatform = msg.sender; // กำหนดกระเป๋า Platform = msg.sender(Deploy)
        platform.created = block.timestamp; // สร้างเมื่อ timestamp
        platform.name = _name; // กำหนดชื่อแพลตฟอร์ม
        platform.percent = _percent; // กำหนดเปอร์เซ็นต์ที่หัก

        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        ); // https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1 ตรง Sepolia Testnet
    }

    // กำหนดสิทธิ Platform
    modifier onlyPlatform() {
        require(msg.sender == platform.AddressPlatform, "You're not Platform");
        _;
    }

    // กำหนดสิทธิ Seller
    modifier onlySeller() {
        require(
            Sellers[msg.sender].AddressSeller == msg.sender,
            "You're not Seller"
        );
        _;
    }

    // กำหนดสิทธิ Customer
    modifier onlyCustomer() {
        require(
            Customers[msg.sender].AddressCustomer == msg.sender,
            "You're not Customer"
        );
        _;
    }

    // กำหนดสิทธิ Transport
    modifier onlyTransport() {
        require(
            Transports[msg.sender].AddressTransport == msg.sender,
            "You're not Transport"
        );
        _;
    }

    // กำหนดสิทธิ ผู้ใช้งานที่อยู่ในระบบ( Seller,Customer,Transport )
    modifier onlyUser() {
        require(
            Sellers[msg.sender].AddressSeller == msg.sender ||
                Customers[msg.sender].AddressCustomer == msg.sender ||
                Transports[msg.sender].AddressTransport == msg.sender,
            "You're not User"
        );
        _;
    }

    // กำหนดสิทธิ ผู้ใช้งานที่อยู่ในระบบ( Platform,Seller,Customer,Transport )
    modifier onlyUserTotel() {
        require(
            platform.AddressPlatform == msg.sender ||
                Sellers[msg.sender].AddressSeller == msg.sender ||
                Customers[msg.sender].AddressCustomer == msg.sender ||
                Transports[msg.sender].AddressTransport == msg.sender,
            "You're not User"
        );
        _;
    }

    // กำหนดสิทธิ ผู้ใช้ใหม่ NewUser ( ที่ไม่ใช่ Platform,Seller,Customer,Transport จะเป็น NewUser )
    modifier onlyNewUser() {
        require(
            msg.sender != platform.AddressPlatform &&
                Sellers[msg.sender].AddressSeller != msg.sender &&
                Customers[msg.sender].AddressCustomer != msg.sender &&
                Transports[msg.sender].AddressTransport != msg.sender,
            "You're not NewUser"
        );
        _;
    }

    // เพิ่มข้อมูล Seller ผู้ขาย
    // onlyPlatform ( onlyPlatform จะมีแต่ Platform เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function addSeller(
        address _AddressSeller,
        string memory _name,
        string memory _tel
    ) public onlyPlatform {
        sellerCounter++;
        uint256 currentTime = block.timestamp;
        Sellers[_AddressSeller] = Seller(
            _AddressSeller,
            currentTime,
            _name,
            _tel
        );
    }

    // แสดงข้อมูล Seller ผู้ขาย โดย กำหนด address ของผู้ขาย
    // onlyUserTotel ( onlyUserTotel ผู้ใช้งานที่อยู่ในระบบ(Platform,Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function getSeller(address _Id)
        public
        view
        onlyUserTotel
        returns (
            address AddressSeller,
            uint256 Created,
            string memory Name,
            string memory Tel
        )
    {
        Seller memory seller = Sellers[_Id];
        return (seller.AddressSeller, seller.created, seller.name, seller.tel);
    }

    // เพิ่มข้อมูล Transport ขนส่ง
    // onlyPlatform ( onlyPlatform จะมีแต่ Platform เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function addTransport(
        address _AddressTransport,
        string memory _name,
        string memory _tel,
        string memory _transportType,
        string memory _exporttype
    ) public onlyPlatform {
        transportCounter++;
        uint256 currentTime = block.timestamp;
        Transports[_AddressTransport] = Transport(
            _AddressTransport,
            currentTime,
            _name,
            _tel,
            _transportType,
            _exporttype
        );
    }

    // แสดงข้อมูล Transport ขนส่ง โดย กำหนด address ของขนส่ง
    // onlyUserTotel ( onlyUserTotel ผู้ใช้งานที่อยู่ในระบบ(Platform,Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function getTransport(address _Id)
        public
        view
        onlyUserTotel
        returns (
            address AddressTransport,
            uint256 Created,
            string memory Name,
            string memory Tel,
            string memory TransportType,
            string memory Exporttype
        )
    {
        Transport memory transport = Transports[_Id];
        return (
            transport.AddressTransport,
            transport.created,
            transport.name,
            transport.tel,
            transport.transportType,
            transport.exporttype
        );
    }

    // เพิ่มข้อมูล Customer ผู้ซื้อ
    // onlyNewUser ( onlyNewUser ที่ไม่ใช่ Seller,Customer,Transport จะเป็น NewUser เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function addCustomer(
        string memory _name,
        string memory _location,
        string memory _tel
    ) public onlyNewUser {
        customerCounter++;
        uint256 currentTime = block.timestamp;
        bytes memory encodedLocation = abi.encode(_location);
        bytes memory encodedTel = abi.encode(_tel);
        Customers[msg.sender] = Customer(
            msg.sender,
            currentTime,
            _name,
            encodedLocation,
            encodedTel
        );
    }

    // แสดงข้อมูล Customer ผู้ซื้อ โดย กำหนด address ของผู้ซื้อ
    // onlyUser ( onlyUser ผู้ใช้งานที่อยู่ในระบบ(Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function getCustomer(address _Id)
        public
        view
        onlyUser
        returns (
            address AddressCustomer,
            uint256 Created,
            string memory Name,
            string memory Location,
            string memory Tel
        )
    {
        Customer memory customer = Customers[_Id];
        string memory decodedLocation = abi.decode(customer.location, (string));
        string memory decodedTel = abi.decode(customer.tel, (string));
        return (
            customer.AddressCustomer,
            customer.created,
            customer.name,
            decodedLocation,
            decodedTel
        );
    }

    // เพิ่มข้อมูล Product
    // onlySeller ( onlySeller จะมีเพียง Seller เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function addProduct(
        uint256 _itemID, // รหัสสินค้า
        string memory _name, // ชื่อสินค้า
        string memory _detail, // รายละเอียดสินค้า
        string memory _ptype, // ประเภทสินค้า
        uint256 _price, // ราคาสินค้า
        uint256 _weight, // น้ำหนักสินค้า
        uint256 _width, // ความกว้างสินค้า
        uint256 _length, // ความยาวสินค้า
        uint256 _height, // ความสูงสินค้า
        uint256 _inventory // จำนวนสินค้า
    ) public onlySeller {
        productCounter++;
        uint256 currentTime = block.timestamp;
        Products[_itemID] = Product(
            _itemID, // รหัสสินค้า
            currentTime, // สร้างเมื่อ
            _name, // ชื่อสินค้า
            _detail, // รายละเอียดสินค้า
            _ptype, // ประเภทสินค้า
            _price, // ราคาสินค้า
            _weight, // น้ำหนักสินค้า
            _width, // ความกว้างสินค้า
            _length, // ความยาวสินค้า
            _height, // ความสูงสินค้า
            _inventory, // จำนวนสินค้า
            msg.sender // ใช้ address เพื่อเป็นที่อยู่ของผู้ขาย
        );
    }

    // แสดงข้อมูล Product
    // onlyUserTotel ( onlyUserTotel ผู้ใช้งานที่อยู่ในระบบ(Platform,Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function getProduct(uint256 _Id)
        public
        view
        onlyUserTotel
        returns (
            uint256 itemID, // รหัสสินค้า
            uint256 created, // สร้างเมื่อ
            string memory name, // ชื่อสินค้า
            string memory detail, // รายละเอียดสินค้า
            string memory ptype, // ประเภทสินค้า
            uint256 price, // ราคาสินค้า
            uint256 weight, // น้ำหนักสินค้า
            uint256 width, // ความกว้างสินค้า
            uint256 length, // ความยาวสินค้า
            uint256 height, // ความสูงสินค้า
            uint256 inventory, // จำนวนสินค้า
            address AddressSeller // ที่อยู่กระเป๋าเงินของผู้ขาย
        )
    {
        Product memory product = Products[_Id];
        return (
            product.itemID, // รหัสสินค้า
            product.created, // สร้างเมื่อ
            product.name, // ชื่อสินค้า
            product.detail, // รายละเอียดสินค้า
            product.ptype, // ประเภทสินค้า
            product.price, // ราคาสินค้า
            product.weight, // น้ำหนักสินค้า
            product.width, // ความกว้างสินค้า
            product.length, // ความยาวสินค้า
            product.height, // ความสูงสินค้า
            product.inventory, // จำนวนสินค้า
            product.AddressSeller // ที่อยู่กระเป๋าเงินของผู้ขาย
        );
    }

    // สร้างคำสั่งซื้อใหม่ Order
    // onlyCustomer ( onlyCustomer จะมีเพียง Customer เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function createOrder(
        uint256[] memory _productIds,
        uint256 _shippingCost,
        address _transportAddress
    ) public payable onlyCustomer {
        uint256 totalOrderPrice = 0;

        // ตรวจสอบ transportAddress เพื่อหาขนส่งที่ถูกลงทะเบียน
        require(
            Transports[_transportAddress].AddressTransport == _transportAddress,
            "Transport address does not exist"
        ); // ไม่มีที่อยู่ขนส่ง

        // เพิ่มสินค้า
        for (uint256 i = 0; i < _productIds.length; i++) {
            uint256 productId = _productIds[i];
            require(Products[productId].itemID != 0, "Product does not exist");
            require(Products[productId].inventory > 0, "Product out of stock");
            Products[productId].inventory--; // ลดจำนวนสินค้าในคลัง
            totalOrderPrice += Products[productId].price; // totalOrderPrice +ราคาสินค้า
        }

        // ราคา(สินค้าทั้งหมด + ค่าขนส่ง)
        totalOrderPrice += _shippingCost;

        uint256 totalOrderPriceInWei = usdToWei(totalOrderPrice);

        // ตรวจสอบว่าเงินที่ส่งมาเพียงพอหรือไม่
        require(
            msg.value >= totalOrderPriceInWei,
            "Insufficient payment"
        ); // การชำระเงินไม่เพียงพอ

        // คืนเงินส่วนเกิน
        if (msg.value >= totalOrderPriceInWei) {
            uint256 excessAmount = (msg.value - (totalOrderPriceInWei));
            payable(msg.sender).transfer(excessAmount);
        }

        // สร้างคำสั่งซื้อ
        orderCounter++;
        uint256 currentTime = block.timestamp;
        Orders[orderCounter] = Order(
            orderCounter,
            currentTime,
            _productIds,
            totalOrderPrice,
            _shippingCost,
            true,
            false,
            false,
            "",
            "",
            msg.sender,
            _transportAddress
        );
    }

    // แสดงรายละเอียดการสั่งซื้อ
    // onlyUser ( onlyUser ผู้ใช้งานที่อยู่ในระบบ(Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function getOrder(uint256 _Id)
        public
        view
        onlyUser
        returns (
            uint256 orderId,
            uint256 created,
            uint256[] memory productIds,
            uint256 sum,
            uint256 shippingCost,
            bool status,
            bool isDelivered,
            bool isReceived,
            string memory noteDelivered,
            string memory noteReceived,
            address customerAddress,
            address transportAddress
        )
    {
        Order memory order = Orders[_Id];
        return (
            order.orderId,
            order.created,
            order.productIds,
            order.sum,
            order.shippingCost,
            order.status,
            order.isDelivered,
            order.isReceived,
            order.noteDelivered,
            order.noteReceived,
            order.customerAddress,
            order.transportAddress
        );
    }

    // ฟังก์ชันสำหรับการตรวจสอบสินค้า ระว่างผู้ขาย-ขนส่ง เพื่อตรวจสอบความถูกต้อวของสินค้าก่อนขนส่งจะรับ (isDelivered = true ขนส่งดำเนินการส่ง / false สัญญาถูกยกเลิกและคืนเงิน)
    // onlyTransport ( onlyTransport จะมีเพียง Transport เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function deliverProduct(
        uint256 _orderId,
        bool _isCheck,
        string memory _noteDelivered
    ) public onlyTransport {
        Order storage order = Orders[_orderId];
        require(order.status == true, "Contract Canceled"); // สัญญาถูกยกเลิก
        require(order.orderId != 0, "Order does not exist"); // ไม่มีคำสั่งซื้อ
        require(order.isDelivered == false, "Product is already delivered"); // สินค้าได้ถูกจัดส่งเรียบร้อยแล้ว
        require(
            order.isReceived == false,
            "The destination receives the product"
        ); // ปลายทางได้รับสินค้า

        // ตรวจสอบว่าสินค้าได้ถูกจัดส่งแล้วหรือยัง
        if (_isCheck) {
            // true สินค้าตรงตรามสัญญา
            order.isDelivered = true;
            order.noteDelivered = _noteDelivered;
        } else {
            //false ยังไม่ได้รับสินค้า หรือ ข้อมูลไม่ตรวจตามที่ตกลงไว้
            order.status = false;
            order.noteDelivered = _noteDelivered;
            uint256 Price = usdToWei(order.sum);
            MyMoney[order.customerAddress] += Price;
            listMoney.push(order.customerAddress);
        }
    }

    // ฟังก์ชันสำหรับการตรวจสอบสินค้า ระว่างขนส่ง-ผู้ซื้อ เพื่อตรวจสอบความถูกต้องของสินค้าก่อนผู้ซื้อจะรับ (isReceived = true เงินจะถูกแจกจ่าย / false สัญญาถูกยกเลิกและคืนเงิน)
    // onlyCustomer ( onlyCustomer จะมีเพียง Customer เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function receiveProduct(
        uint256 _orderId,
        bool _isCheck,
        string memory _noteReceived
    ) public onlyCustomer {
        Order storage order = Orders[_orderId];
        require(order.status == true, "Contract Canceled"); // สัญญาถูกยกเลิก
        require(order.orderId != 0, "Order does not exist"); // ไม่มีคำสั่งซื้อ
        require(order.isDelivered == true, "Product is not yet delivered"); //สินค้ายังไม่ได้จัดส่ง
        require(
            order.isReceived == false,
            "The destination receives the product"
        ); //ปลายทางได้รับสินค้า

        // ตรวจสอบว่าสินค้าได้ถูกจัดส่งแล้วหรือยัง
        if (_isCheck) {
            // true สินค้าตรงตรามสัญญา
            order.isReceived = true;
            order.noteReceived = _noteReceived;

            uint256 PriceSUM = usdToWei(order.sum);

            // รวมค่าสินค้า -หักเปอร์เซ็นจากPlatform
            for (uint256 i = 0; i < order.productIds.length; i++) {
                uint256 productId = order.productIds[i];
                address sellerAddress = Products[productId].AddressSeller;
                uint256 sellerAmount = Products[productId].price;
                uint256 sellerPrice = usdToWei(sellerAmount);
                uint256 platformSeller = sellerPrice -
                    ((sellerPrice * platform.percent) / 100 );
                PriceSUM -= platformSeller;
                MyMoney[sellerAddress] += platformSeller;
                listMoney.push(sellerAddress);
            }

            // ค่าขนส่ง -หักเปอร์เซ็นจากPlatform
            address transportAddress = Transports[order.transportAddress]
                .AddressTransport;
            uint256 transportPrice = usdToWei(order.shippingCost) ;
            uint256 platformTransport = transportPrice -
                ((usdToWei(order.shippingCost ) * platform.percent) / 100 );
            PriceSUM -= platformTransport;
            MyMoney[transportAddress] += platformTransport;
            listMoney.push(transportAddress);

            // Platform เปอร์เซ็นที่ได้
            MyMoney[platform.AddressPlatform] += PriceSUM;
            listMoney.push(platform.AddressPlatform);
        } else {
            //false ยังไม่ได้รับสินค้า หรือ ข้อมูลไม่ตรวจตามที่ตกลงไว้
            order.status = false;
            order.noteReceived = _noteReceived;
            uint256 Price = usdToWei(order.sum);
            MyMoney[order.customerAddress] += Price;
            listMoney.push(order.customerAddress);
        }
    }

    // ถอดเงินได้เมื่อทุกๆ Address มีเงินเป็น 0
    // onlyUserTotel ( onlyUserTotel ผู้ใช้งานที่อยู่ในระบบ(Platform,Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function withdrawTotal() public payable onlyUserTotel {
        uint256 amountToWithdraw = MyMoney[msg.sender]; // จำนวนเงินทั้งหมดที่ผู้ถอด

        require(
            amountToWithdraw > 0,
            "Insufficient balance in Contract"
        );

        payable(msg.sender).transfer(amountToWithdraw); // ถอนเงิน

        // กำหนดเงินในบัญชีของผู้ถอดให้เป็น 0
        MyMoney[msg.sender] = 0;
    }

    // เช็คข้อมูลหน่วยเงิน(USDล่าสุด)
    function latestRoundData() private view returns (uint256) {
        (, int256 answer, , , ) = dataFeed.latestRoundData();
        return uint256(answer) / (1e8);
    }

    // แปลงจาก USD เป็น Ether 
    function usdToWei(uint256 usdAmount) private view returns  (uint256) { 
        uint256 ethPriceInUSD = latestRoundData(); 
        uint256 weiAmount = (usdAmount * 1e18) / ethPriceInUSD; 
        return weiAmount;
    }

    // ตรวจสอบเงินใน Smart Contract
    // onlyUserTotel ( onlyUserTotel ผู้ใช้งานที่อยู่ในระบบ(Platform,Seller,Customer,Transport) เท่านั้นที่สามารถใช้งานฟังก์ชันนี้ )
    function checkMoney() public view onlyUserTotel returns (uint256) {
        return MyMoney[msg.sender];
    }
}
