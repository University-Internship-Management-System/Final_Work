using System;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web.UI.WebControls;
using Newtonsoft.Json.Linq;

namespace UniversityInternshipManagmentSystem.Config
{
    // Image upload to Cloudinary (the company logo). The key file comes from Config/TeamKeys.cs.
    public static class Cloudinary
    {
        // Checks the file chosen in a FileUpload control: a real JPG or PNG, 2 MB at most. Throws FormatException when it is not.
        public static byte[] ReadImage(FileUpload upload)
        {
            string extension = Path.GetExtension(upload.FileName).ToLowerInvariant();
            if (upload.PostedFile.ContentLength > 2 * 1024 * 1024 || (extension != ".jpg" && extension != ".jpeg" && extension != ".png"))
                throw new FormatException("Choose a JPG or PNG image up to 2 MB.");

            byte[] bytes = upload.FileBytes;
            bool png = bytes.Length >= 8 && bytes.Take(8).SequenceEqual(new byte[] { 137, 80, 78, 71, 13, 10, 26, 10 });
            bool jpeg = bytes.Length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255;
            if (!png && !jpeg) throw new FormatException("Choose a JPG or PNG image up to 2 MB.");
            return bytes;
        }

        // Uploads the image (shrunk to 512 x 512 at most) and returns its https address.
        public static async Task<string> Upload(byte[] image, string publicId)
        {
            JObject result = await Send("upload", publicId, image);
            string url = (string)result["secure_url"];
            Uri uri;
            if (!Uri.TryCreate(url, UriKind.Absolute, out uri) || uri.Scheme != "https") throw new InvalidOperationException("Cloudinary did not return an https address.");
            return url;
        }

        // Removes an uploaded image (used when saving the profile failed). It never throws: the old image just stays on Cloudinary.
        public static async Task Delete(string publicId)
        {
            try { await Send("destroy", publicId, null); }
            catch { }
        }

        static async Task<JObject> Send(string action, string publicId, byte[] image)
        {
            string path = TeamKeys.FindFile(TeamKeys.CloudinaryVariable, TeamKeys.CloudinaryFile);
            if (path == null) throw new InvalidOperationException("The Cloudinary key file was not found.");
            var settings = JObject.Parse(File.ReadAllText(path));
            string cloud = ((string)settings["cloud_name"] ?? "").Trim();
            string key = ((string)settings["api_key"] ?? "").Trim();
            string secret = ((string)settings["api_secret"] ?? "").Trim();
            if (!Regex.IsMatch(cloud, @"\A[a-zA-Z0-9_-]+\z") || key == "" || secret == "")
                throw new InvalidOperationException("The Cloudinary key file is not filled in.");

            string timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture);
            string parameters = "public_id=" + publicId + "&timestamp=" + timestamp;
            if (image != null) parameters = "allowed_formats=jpg,png&" + parameters + "&transformation=c_limit,h_512,w_512";
            string signature;
            using (var hash = SHA256.Create())
                signature = BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(parameters + secret))).Replace("-", "").ToLowerInvariant();

            using (var body = new MultipartFormDataContent())
            {
                body.Add(new StringContent(publicId), "public_id");
                body.Add(new StringContent(timestamp), "timestamp");
                body.Add(new StringContent(key), "api_key");
                body.Add(new StringContent(signature), "signature");
                if (image != null)
                {
                    bool png = image[0] == 137;
                    body.Add(new StringContent("jpg,png"), "allowed_formats");
                    body.Add(new StringContent("c_limit,h_512,w_512"), "transformation");
                    var file = new ByteArrayContent(image);
                    file.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(png ? "image/png" : "image/jpeg");
                    body.Add(file, "file", png ? "logo.png" : "logo.jpg");
                }
                using (var response = await FirebaseDb.client.PostAsync("https://api.cloudinary.com/v1_1/" + cloud + "/image/" + action, body))
                {
                    if (!response.IsSuccessStatusCode) throw new InvalidOperationException("Cloudinary answered " + (int)response.StatusCode + ".");
                    return JObject.Parse(await response.Content.ReadAsStringAsync());
                }
            }
        }
    }
}
