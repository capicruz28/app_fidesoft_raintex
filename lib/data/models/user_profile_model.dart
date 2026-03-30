// lib/data/models/user_profile_model.dart
import 'dart:convert';

UserProfileModel userProfileModelFromJson(String str) => UserProfileModel.fromJson(json.decode(str));
String userProfileModelToJson(UserProfileModel data) => json.encode(data.toJson());

class UserProfileModel {
  final int usuarioId;
  final String nombreUsuario;
  final String correo;
  final String nombre;
  final String apellido;
  final bool esActivo;
  final String? telefono;
  final String? codigoTrabajadorExterno;
  final String? tipoTrabajador;
  final String? descripcionUsuario;
  final String? area;
  final String? cargo;
  final List<String>? roles;

  UserProfileModel({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.esActivo,
    this.telefono,
    this.codigoTrabajadorExterno,
    this.tipoTrabajador,
    this.descripcionUsuario,
    this.area,
    this.cargo,
    this.roles,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
        usuarioId: json["usuario_id"] ?? json["usuarioId"] ?? 0,
        nombreUsuario: json["nombre_usuario"] ?? json["nombreUsuario"] ?? "",
        correo: json["correo"] ?? "",
        nombre: json["nombre"] ?? "",
        apellido: json["apellido"] ?? "",
        esActivo: json["es_activo"] ?? json["esActivo"] ?? true,
        telefono: json["telefono"]?.toString(),
        codigoTrabajadorExterno: json["codigo_trabajador_externo"] ?? json["codigoTrabajadorExterno"],
        tipoTrabajador: json["tipo_trabajador"] ?? json["tipoTrabajador"],
        descripcionUsuario: json["descripcion_usuario"] ?? json["descripcionUsuario"],
        area: json["area"],
        cargo: json["cargo"],
        roles: json["roles"] != null ? List<String>.from(json["roles"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "usuario_id": usuarioId,
        "nombre_usuario": nombreUsuario,
        "correo": correo,
        "nombre": nombre,
        "apellido": apellido,
        "es_activo": esActivo,
        "telefono": telefono,
        "codigo_trabajador_externo": codigoTrabajadorExterno,
        "tipo_trabajador": tipoTrabajador,
        "descripcion_usuario": descripcionUsuario,
        "area": area,
        "cargo": cargo,
        "roles": roles,
      };

  String get nombreCompleto => '$nombre $apellido'.trim();
}
