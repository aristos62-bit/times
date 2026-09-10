// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserSettingsTable get userSettings => attachedDatabase.userSettings;
  SettingDaoManager get managers => SettingDaoManager(this);
}

class SettingDaoManager {
  final _$SettingDaoMixin _db;
  SettingDaoManager(this._db);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db.attachedDatabase, _db.userSettings);
}
