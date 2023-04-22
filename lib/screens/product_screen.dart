import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:productos_app/providers/product_form_provider.dart';
import 'package:productos_app/services/services.dart';
import 'package:productos_app/ui/input_decorations.dart';
import 'package:productos_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productsService = Provider.of<ProductsService>(context);

    return ChangeNotifierProvider(
      create: (_) => ProductFormProvider(productsService.selectedProduct),
      child: _ProductScreenBody(productsService: productsService),
    );
  }
}

class _ProductScreenBody extends StatelessWidget {
  const _ProductScreenBody({
    super.key,
    required this.productsService,
  });

  final ProductsService productsService;

  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    return Scaffold(
      body: SingleChildScrollView(
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

        child: Column(
          children: [
            Stack(
              children: [
                ProductImage(
                  url: productsService.selectedProduct.picture,
                ),
                Positioned(
                  top: 60,
                  left: 20,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 20,
                  child: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        backgroundColor: Colors.blueAccent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        elevation: 20,
                        context: context,
                        builder: (context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(
                                    Icons.photo_camera_back_outlined),
                                title: const Text('Camara'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final picker = ImagePicker();
                                  //TODO: implementar bottomSheet para dar opción de camara o galeria
                                  final XFile? pickedFile =
                                      await picker.pickImage(
                                          source: ImageSource.camera,
                                          imageQuality: 100);

                                  if (pickedFile == null) {
                                    print('No selecciono nada');
                                    return;
                                  }

                                  // print('Tenemos imagen ${pickedFile.path}');
                                  productsService.updateSelectedProductImage(
                                      pickedFile.path);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo),
                                title: const Text('Galeria'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final picker = ImagePicker();
                                  //TODO: implementar bottomSheet para dar opción de camara o galeria
                                  final XFile? pickedFile =
                                      await picker.pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 100);

                                  if (pickedFile == null) {
                                    print('No selecciono nada');
                                    return;
                                  }

                                  // print('Tenemos imagen ${pickedFile.path}');
                                  productsService.updateSelectedProductImage(
                                      pickedFile.path);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const _ProductForm(),
            const SizedBox(height: 100)
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: productsService.isSaving
            ? null
            : () async {
                //TODO: Guardar producto
                if (!productForm.isValidForm()) return;

                final String? imageUrl = await productsService.uploadImage();

                // print(imageUrl);

                if (imageUrl != null) {
                  productForm.product.picture = imageUrl;
                }

                await productsService.saveOrCreateProduct(productForm.product);
              },
        child: productsService.isSaving
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const Icon(Icons.save_outlined),
      ),
    );
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final productForm = Provider.of<ProductFormProvider>(context);
    final product = productForm.product;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        decoration: _buildBoxDecoration(),
        child: Form(
          key: productForm.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextFormField(
                initialValue: product.name,
                onChanged: (value) => product.name = value,
                validator: (value) {
                  if (value == null || value.length < 1) {
                    return 'El nombre es obligatario';
                  }
                },
                decoration: InputDecorations.authInputDecoration(
                  hintText: "Nombre del producto",
                  labelText: "Nombre: ",
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              TextFormField(
                initialValue: '${product.price}',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^(\d+)?\.?\d{0,2}'))
                ],
                onChanged: (value) {
                  if (double.tryParse(value) == null) {
                    product.price = 0;
                  } else {
                    product.price = double.parse(value);
                  }
                },
                keyboardType: TextInputType.number,
                decoration: InputDecorations.authInputDecoration(
                  hintText: "\$150",
                  labelText: "Precio: ",
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              SwitchListTile.adaptive(
                value: product.available,
                title: Text("Disponible"),
                activeColor: Colors.indigo,
                onChanged: productForm.updateAvailability,
              ),
              const SizedBox(
                height: 30,
              )
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoxDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 5),
            blurRadius: 5,
          )
        ],
      );
}
