import 'package:flutter/material.dart';
import 'package:glamup/controllers/address_controller.dart';
import 'package:glamup/models/address.dart';
import 'package:glamup/services/api_service.dart';

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({super.key});

  @override
  _AddressManagementPageState createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  final AddressController _addressController = AddressController(apiService: ApiService());
  List<Address> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      var items = await _addressController.getAddresses();
      
      setState(() {
        addresses = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load addresses: $e'))
      );
      print(e);
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await _addressController.deleteAddress(id);
      loadAddresses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address removed successfully'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove address: $e'))
      );
    }
  }

  void _showAddEditAddressDialog({Address? address}) {
    final formKey = GlobalKey<FormState>();
    String fullName = address?.fullName ?? '';
    String phone = address?.phone ?? '';
    String addressLine = address?.addressLine ?? '';
    String city = address?.city ?? '';
    String state = address?.state ?? '';
    String zipCode = address?.zipCode ?? '';
    String country = address?.country ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(address == null ? 'Add New Address' : 'Edit Address'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: fullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => fullName = value,
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => phone = value,
                ),
                TextFormField(
                  initialValue: addressLine,
                  decoration: const InputDecoration(labelText: 'Address Line'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => addressLine = value,
                ),
                TextFormField(
                  initialValue: city,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => city = value,
                ),
                TextFormField(
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'State/Province'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => state = value,
                ),
                TextFormField(
                  initialValue: zipCode,
                  decoration: const InputDecoration(labelText: 'ZIP/Postal Code'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => zipCode = value,
                ),
                TextFormField(
                  initialValue: country,
                  decoration: const InputDecoration(labelText: 'Country'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onChanged: (value) => country = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  if (address == null) {
                    await _addressController.addAddress(
                      fullName, phone, addressLine, city, state, zipCode, country
                    );
                  } else {
                    await _addressController.updateAddress(
                      address.id, fullName, phone, addressLine, city, state, zipCode, country
                    );
                  }
                  Navigator.pop(context);
                  loadAddresses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address saved successfully'))
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save address: $e'))
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Addresses"),
        centerTitle: true,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : addresses.isEmpty 
          ? _buildEmptyAddresses(context)
          : _buildAddressesList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAddressDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyAddresses(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            "No addresses found",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Add a new shipping address",
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_location_alt),
            label: const Text("Add New Address"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () => _showAddEditAddressDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        var address = addresses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      address.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditAddressDialog(address: address),
                          tooltip: "Edit",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteAddress(address.id),
                          tooltip: "Delete",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address.phone),
                const SizedBox(height: 8),
                Text(address.addressLine),
                Text('${address.city}, ${address.state} ${address.zipCode}'),
                Text(address.country),
              ],
            ),
          ),
        );
      },
    );
  }
}