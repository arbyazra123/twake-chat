import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:logger/logger.dart';
import 'package:twake/blocs/file_cubit/download/file_download_state.dart';
import 'package:twake/models/file/download/file_downloading.dart';
import 'package:twake/models/file/file.dart';
import 'package:twake/models/file/message_file.dart';
import 'package:twake/repositories/file_repository.dart';
import 'package:twake/utils/extensions.dart';
import 'package:twake/utils/utilities.dart';

class FileDownloadCubit extends Cubit<FileDownloadState> {
  late final FileRepository _repository;

  FileDownloadCubit({FileRepository? repository}) : super(FileDownloadState()) {
    if (repository == null) {
      repository = FileRepository();
    }
    _repository = repository;
  }

  void download(
      {required BuildContext context,
      File? file,
      MessageFile? messageFile}) async {
    // make sure storage permission is granted before downloading
    final isGranted = await Utilities.checkAndRequestStoragePermission(
        permissionType: PermissionStorageType.WriteExternalStorage,
        onPermanentlyDenied: () =>
            Utilities.showOpenSettingsDialog(context: context));
    if (!isGranted) return;

    List<FileDownloading> listFileDownloading = [...state.listFileDownloading];

    // add new file downloading to state
    final newFileDownloading = FileDownloading(
      file: file,
      messageFile: messageFile,
      downloadStatus: FileItemDownloadStatus.downloadInProgress,
    );
    emit(state.copyWith(
        listFileDownloading: listFileDownloading..add(newFileDownloading)));
    // start downloading file
    try {
      final result =
          await _repository.downloadFile(fileDownloading: newFileDownloading);
      final taskId = result.item1;
      final savedPath = result.item2;
      if (state.listFileDownloading.isEmpty) return;
      if (taskId == null) {
        handleDownloadFailed(file: file, messageFile: messageFile);
        return;
      }
      final updatedStateList = state.listFileDownloading.map((fileDownloading) {
        return fileDownloading.messageFile == null
            ? fileDownloading.file!.id == file!.id
                ? fileDownloading.copyWith(
                    downloadTaskId: taskId, savedPath: savedPath)
                : fileDownloading
            : fileDownloading.messageFile!.metadata.externalId ==
                    messageFile!.metadata.externalId
                ? fileDownloading.copyWith(
                    downloadTaskId: taskId, savedPath: savedPath)
                : fileDownloading;
      }).toList();
      emit(state.copyWith(listFileDownloading: updatedStateList));
    } catch (e) {
      Logger().e('Error occurred during file downloading:\n$e');
      handleDownloadFailed(file: file, messageFile: messageFile);
    }
  }

  // Update failed status by [file] or [taskId]
  void handleDownloadFailed(
      {File? file, MessageFile? messageFile, String? taskId}) {
    if (state.listFileDownloading.isEmpty) return;
    if (file != null || messageFile != null) {
      final List<FileDownloading>? updatedStateList =
          state.listFileDownloading.map((fileDownloading) {
        return messageFile == null
            ? fileDownloading.file!.id == file!.id
                ? fileDownloading.copyWith(
                    downloadStatus: FileItemDownloadStatus.downloadFailed)
                : fileDownloading
            : fileDownloading.messageFile!.metadata.externalId ==
                    messageFile.metadata.externalId
                ? fileDownloading.copyWith(
                    downloadStatus: FileItemDownloadStatus.downloadFailed)
                : fileDownloading;
      }).toList();

      emit(state.copyWith(listFileDownloading: updatedStateList));
      return;
    }
    if (taskId != null) {
      final updatedStateList = state.listFileDownloading.map((fileDownloading) {
        return fileDownloading.downloadTaskId == taskId
            ? fileDownloading.copyWith(
                downloadStatus: FileItemDownloadStatus.downloadFailed)
            : fileDownloading;
      }).toList();
      emit(state.copyWith(listFileDownloading: updatedStateList));
      return;
    }
  }

  void handleAfterDownloaded(
      {required String taskId, required BuildContext context}) async {
    if (state.listFileDownloading.isEmpty) return;
    FileDownloading? fileDownloaded;
    final updatedStateList = state.listFileDownloading.map((fileDownloading) {
      if (fileDownloading.downloadTaskId == taskId) {
        fileDownloaded = fileDownloading;
        return fileDownloading.copyWith(
            downloadStatus: FileItemDownloadStatus.downloadSuccessful);
      }
      return fileDownloading;
    }).toList();
    emit(state.copyWith(listFileDownloading: updatedStateList));

    // save to gallery if this is media
    final isPhotoGranted = await Utilities.checkAndRequestPhotoPermission(
        onPermanentlyDenied: () =>
            Utilities.showOpenSettingsDialog(context: context));
    if (!isPhotoGranted) return;
    if (fileDownloaded != null && fileDownloaded!.savedPath != null) {
      if (fileDownloaded!.file != null) {
        if (fileDownloaded!.file!.metadata.mime.isImageMimeType) {
          await ImageGallerySaver.saveFile(fileDownloaded!.savedPath!);
        } else if (fileDownloaded!.file!.metadata.mime.isVideoMimeType) {
          await ImageGallerySaver.saveFile(fileDownloaded!.savedPath!);
        }
      } else {
        if (fileDownloaded!.messageFile!.metadata.mime.isImageMimeType) {
          await ImageGallerySaver.saveFile(fileDownloaded!.savedPath!);
        } else if (fileDownloaded!.messageFile!.metadata.mime.isVideoMimeType) {
          await ImageGallerySaver.saveFile(fileDownloaded!.savedPath!);
        }
      }
    }
  }

  void addToDownloadStateAfterUploaded(
      {required File file, required String localPath}) {
    List<FileDownloading> listFileDownloading = [...state.listFileDownloading];

    // add new file downloading to state
    final newFileDownloading = FileDownloading(
        file: file,
        downloadStatus: FileItemDownloadStatus.downloadSuccessful,
        savedPath: localPath);
    emit(state.copyWith(
        listFileDownloading: listFileDownloading..add(newFileDownloading)));
  }

  void cancelDownloadingFile({required String downloadTaskId}) {
    _repository.cancelDownloadingFile(downloadTaskId: downloadTaskId);
    if (state.listFileDownloading.isEmpty) return;
    final updatedStateList = [...state.listFileDownloading];
    updatedStateList
        .removeWhere((file) => file.downloadTaskId == downloadTaskId);
    emit(state.copyWith(listFileDownloading: updatedStateList));
  }

  Future<bool> openDownloadedFile({required String downloadTaskId}) async {
    return await _repository.openDownloadedFile(downloadTaskId: downloadTaskId);
  }

  void removeDownloadingFile({required String downloadTaskId}) {
    if (state.listFileDownloading.isEmpty) return;
    final updatedStateList = [...state.listFileDownloading];
    updatedStateList
        .removeWhere((file) => file.downloadTaskId == downloadTaskId);
    emit(state.copyWith(listFileDownloading: updatedStateList));
  }
}
