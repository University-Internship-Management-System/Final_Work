using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace UniversityInternshipManagmentSystem.Student.Data
{
    public static class ProfileValidation
    {
        public static IDictionary<string, object> CreatePatch(string phone, string skillsText, string cv, string portfolio, ISet<string> authorized)
        {
            var patch = new Dictionary<string, object>(StringComparer.Ordinal);
            if (authorized == null) throw new UnauthorizedAccessException("No profile fields are authorized for editing.");
            if (authorized.Contains("PhoneNumber")) patch["PhoneNumber"] = (phone ?? "").Trim();
            if (authorized.Contains("SkillsList"))
            {
                if (skillsText != null && skillsText.Length > 2000) throw new ArgumentException("The skills list is too long.");
                patch["SkillsList"] = (skillsText ?? "").Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(value => value.Trim()).Where(value => value.Length > 0)
                    .Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            }
            if (authorized.Contains("CvUrl")) patch["CvUrl"] = (cv ?? "").Trim();
            if (authorized.Contains("PortfolioUrl")) patch["PortfolioUrl"] = (portfolio ?? "").Trim();
            ValidatePatch(patch, authorized);
            return patch;
        }

        public static bool MatchesPatch(StudentRecord record, IDictionary<string, object> patch)
        {
            if (record == null || patch == null) return false;
            foreach (var pair in patch)
            {
                switch (pair.Key)
                {
                    case "PhoneNumber": if (record.PhoneNumber != (string)pair.Value) return false; break;
                    case "CvUrl": if (record.CvUrl != (string)pair.Value) return false; break;
                    case "PortfolioUrl": if (record.PortfolioUrl != (string)pair.Value) return false; break;
                    // Firebase removes an empty array; null is equivalent only for an empty skills list.
                    case "SkillsList": if (!(record.SkillsList ?? new List<string>()).SequenceEqual((IList<string>)pair.Value)) return false; break;
                    default: return false;
                }
            }
            return true;
        }
        // Return a copy so callers cannot expand the module's permanent field policy.
        public static ISet<string> EditableFields => new HashSet<string>(StringComparer.Ordinal)
        { "PhoneNumber", "SkillsList", "CvUrl", "PortfolioUrl" };

        public static bool IsSafeUrl(string value)
        {
            Uri uri;
            return !string.IsNullOrWhiteSpace(value) && value.Length <= 2048
                && Uri.TryCreate(value, UriKind.Absolute, out uri) && uri.Scheme == Uri.UriSchemeHttps
                && !string.IsNullOrEmpty(uri.Host) && string.IsNullOrEmpty(uri.UserInfo)
                && !value.Any(char.IsControl);
        }

        public static void ValidatePatch(IDictionary<string, object> changes, ISet<string> authorized)
        {
            if (changes == null || changes.Count == 0) throw new ArgumentException("There are no authorized changes to save.");
            foreach (var pair in changes)
            {
                if (!EditableFields.Contains(pair.Key) || authorized == null || !authorized.Contains(pair.Key))
                    throw new UnauthorizedAccessException("This profile field is read-only.");
                if (pair.Key == "SkillsList")
                {
                    var skills = pair.Value as IList<string>;
                    if (skills == null || skills.Count > 20 || skills.Any(s => string.IsNullOrWhiteSpace(s)
                        || s.Length > 60 || s.Any(char.IsControl)))
                        throw new ArgumentException("Enter up to 20 skills, each between 1 and 60 characters.");
                }
                else
                {
                    var value = pair.Value as string;
                    if (value == null) throw new ArgumentException("Invalid profile field value.");
                    if (pair.Key == "PhoneNumber")
                    {
                        if (value.Length > 30 || value.Any(char.IsControl) || (value.Length > 0 && (!Regex.IsMatch(value, @"\A\+?[0-9 ()\-]{7,30}\z")
                            || value.Count(c => c >= '0' && c <= '9') < 7)))
                            throw new ArgumentException("Enter a phone number with 7–30 characters using digits, spaces, +, parentheses, or hyphens.");
                    }
                    else if (value.Length > 0 && !IsSafeUrl(value))
                        throw new ArgumentException("CV and portfolio links must be absolute HTTPS URLs without embedded credentials (up to 2048 characters).");
                }
            }
        }
    }
}
