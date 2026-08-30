/**
 * bi-modules' own components (BiNavComponent, BIGridComponent, the SweetAlert2
 * delete confirmation, etc.) call TranslateService.instant(key) for every
 * message they show - toolbar validation, "saved successfully", the delete
 * confirmation dialog. With no loader/catalog configured, ngx-translate falls
 * back to returning the raw key, which is why those messages showed up
 * verbatim (e.g. "Savependingchanges", "ConfirmDelete") instead of real text.
 * Keys collected by grepping every `translateService.instant("...")` call in
 * the compiled bi-modules bundle - see EnTranslateLoader in translate-loader.ts.
 */
export const EN_TRANSLATIONS: Record<string, string> = {
  Cancel: 'Cancel',
  CantSaveMoreThan1000AtOnce: "You can't save more than 1000 rows at once.",
  Close: 'Close',
  ConfirmDelete: 'Are you sure you want to delete this record?',
  CustomizeColumns: 'Customize Columns',
  SavedSuccessfully: 'Saved successfully',
  Savependingchanges: 'Please save your pending changes first',
  SetAsDefault: 'Set as Default',
  'four-column': 'Four columns',
  noValidDataToSave: 'There is no valid data to save',
  'one-column': 'One column',
  selectDelete: 'Please select a row to delete',
  'three-column': 'Three columns',
  'two-column': 'Two columns',
  yes: 'Yes',
  Attachments: 'Attachments',
  ComplexPasswordError: 'Password must contain uppercase, lowercase, numbers and special characters',
  Emailaddressisinvalid: 'Email address is invalid',
  Filter: 'Filter',
  'Filter...': 'Filter...',
  'Image needs to be JPG, PNG, JPEG, GIF': 'Image needs to be JPG, PNG, JPEG, GIF',
  'Image needs to be smaller than 2MB': 'Image needs to be smaller than 2MB',
  IsInvalid: 'is invalid',
  Length: 'Length',
  MedumPasswordError: 'Password strength is medium',
  NotFutureDate: 'Date cannot be in the future',
  OK: 'OK',
  PasswordTooWeak: 'Password is too weak',
  PleaseEnterValidData: 'Please enter valid data',
  PleaseSelectRowToGetInformation: 'Please select a row to view its information',
  RecordInformation: 'Record Information',
  RecordedDeletedSuccessfully: 'Record deleted successfully',
  SavedsuccessufellyKey: 'Saved successfully',
  SelectRowToAttach: 'Please select a row to attach a file',
  Sort: 'Sort',
  'Wrong File Extension': 'Wrong file extension',
  'Wrong File Size': 'Wrong file size',
  cantBeEmpty: 'cannot be empty',
  cantfind: 'Not found',
  error: 'Error',
  inputIsNotInACorrectFormat: 'Input is not in the correct format',
  matDatepickerParse: 'Invalid date',
  maxLenghtIs: 'Maximum length is',
  maxValueIs: 'Maximum value is',
  minLenghtIs: 'Minimum length is',
  minValueIs: 'Minimum value is',
  withenteredvalue: 'with entered value'
};
