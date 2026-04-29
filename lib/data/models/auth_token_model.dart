// lib/data/models/auth_token_model.dart
import 'dart:convert';

AuthTokenModel authTokenModelFromJson(String str) => AuthTokenModel.fromJson(json.decode(str));

class AuthTokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserData? userData; // Datos del usuario si vienen en la respuesta

  AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    this.userData,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) => AuthTokenModel(
        accessToken: json["access_token"] ?? json["accessToken"] ?? "",
        refreshToken: json["refresh_token"] ?? json["refreshToken"] ?? "",
        tokenType: json["token_type"] ?? json["tokenType"] ?? "bearer",
        userData: json["user_data"] != null ? UserData.fromJson(json["user_data"]) : null,
      );
}

class UserData {
  final int? usuarioId;
  final String? nombreUsuario;
  final String? correo;
  final String? nombre;
  final String? apellido;
  final bool? esActivo;
  final String? codigoTrabajadorExterno;
  final List<String>? roles;

  UserData({
    this.usuarioId,
    this.nombreUsuario,
    this.correo,
    this.nombre,
    this.apellido,
    this.esActivo,
    this.codigoTrabajadorExterno,
    this.roles,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        usuarioId: json["usuario_id"] ?? json["usuarioId"],
        nombreUsuario: json["nombre_usuario"] ?? json["nombreUsuario"],
        correo: json["correo"],
        nombre: json["nombre"],
        apellido: json["apellido"],
        esActivo: json["es_activo"] ?? json["esActivo"],
        codigoTrabajadorExterno: json["codigo_trabajador_externo"] ?? json["codigoTrabajadorExterno"],
        roles: json["roles"] != null ? List<String>.from(json["roles"]) : null,
      );
}
