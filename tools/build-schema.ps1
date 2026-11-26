# Membangun ulang data terstruktur (JSON-LD) di index.html, di antara <!--SCHEMA--> dan <!--/SCHEMA-->.
# Jalankan setiap kali FAQ, tarif, alamat, atau jam layanan diubah:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/build-schema.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$file = Join-Path $root 'index.html'
$html = [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8)
$site = 'https://hipnoterapicenter.vercel.app/'

function Strip([string]$s) {
  $s = [regex]::Replace($s, '<[^>]+>', '')
  [Net.WebUtility]::HtmlDecode($s).Trim()
}

# --- FAQ diambil langsung dari bagian FAQ halaman ---
$faqStart = $html.IndexOf('<section id="faq"')
$faqEnd = $html.IndexOf('</section>', $faqStart)
$faqHtml = $html.Substring($faqStart, $faqEnd - $faqStart)
$qa = @()
foreach ($m in [regex]::Matches($faqHtml, '<details[^>]*><summary>([^<]+)</summary><p>(.*?)</p></details>')) {
  $qa += [ordered]@{
    '@type' = 'Question'
    name = Strip $m.Groups[1].Value
    acceptedAnswer = [ordered]@{ '@type' = 'Answer'; text = Strip $m.Groups[2].Value }
  }
}

$hours = [ordered]@{
  '@type' = 'OpeningHoursSpecification'
  dayOfWeek = @('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
  opens = '09:00'; closes = '16:00'
}
function Offer($name, $desc, $price) {
  [ordered]@{
    '@type' = 'Offer'
    itemOffered = [ordered]@{ '@type' = 'Service'; name = $name; description = $desc }
    price = $price; priceCurrency = 'IDR'
  }
}

$graph = @(
  [ordered]@{
    '@type' = @('MedicalBusiness','LocalBusiness')
    '@id' = $site + '#klinik'
    name = 'Hipnoterapi Center'
    alternateName = @('Hipnoterapi Lampung','Klinik Hipnoterapi Center','Hipnoterapi Center Bandar Lampung')
    slogan = 'Pulihkan Pikiran, Bangkitkan Hidup'
    description = 'Klinik hipnoterapi di Kedaton, Bandar Lampung, untuk kecemasan, serangan panik, susah tidur, fobia, trauma, keluhan psikosomatis, kecanduan, serta masalah anak dan remaja. Sesi tatap muka dan online.'
    url = $site
    logo = $site + 'img/logo.jpg'
    image = $site + 'img/logo.jpg'
    telephone = '+628127154447'
    contactPoint = @(
      [ordered]@{ '@type'='ContactPoint'; telephone='+628127154447'; contactType='customer service'; availableLanguage='id' },
      [ordered]@{ '@type'='ContactPoint'; telephone='+6281351962596'; contactType='customer service'; availableLanguage='id' },
      [ordered]@{ '@type'='ContactPoint'; telephone='+6281368737339'; contactType='customer service'; availableLanguage='id' }
    )
    address = [ordered]@{
      '@type' = 'PostalAddress'
      streetAddress = 'Jl. Soekarno Hatta, Gg. Sawah Baru, Kp. Baru, Kec. Kedaton'
      addressLocality = 'Bandar Lampung'
      addressRegion = 'Lampung'
      postalCode = '35141'
      addressCountry = 'ID'
    }
    hasMap = 'https://maps.app.goo.gl/iymZhz5aHDYLSnEc9'
    geo = [ordered]@{ '@type' = 'GeoCoordinates'; latitude = -5.360243; longitude = 105.2464019 }
    areaServed = @('Bandar Lampung','Provinsi Lampung','Indonesia')
    openingHoursSpecification = @($hours)
    priceRange = 'Rp400.000 - Rp8.700.000'
    currenciesAccepted = 'IDR'
    knowsAbout = @('Hipnoterapi','Kecemasan','Serangan panik','Insomnia','Fobia','Trauma','Psikosomatis','Asam lambung karena stres','Berhenti merokok','Kecanduan gawai','Hipnoterapi anak','Percaya diri')
    hasOfferCatalog = [ordered]@{
      '@type' = 'OfferCatalog'
      name = 'Layanan hipnoterapi'
      itemListElement = @(
        (Offer 'Sesi hipnoterapi - Terapis Profesional' 'Keluhan ringan hingga sedang: stres harian, sulit tidur, kurang percaya diri, kebiasaan ringan.' '400000'),
        (Offer 'Sesi hipnoterapi - Terapis Spesialis' 'Kecemasan menetap, serangan panik, fobia, trauma, dan kebiasaan yang sulit diubah.' '600000'),
        (Offer 'Sesi hipnoterapi - Terapis Senior Berpengalaman' 'Kasus kompleks atau yang sudah lama dialami.' '800000'),
        (Offer 'Program hipnoterapi intensif' 'Rangkaian sesi terstruktur dengan asesmen awal untuk masalah berat. Harga mulai.' '7500000')
      )
    }
  },
  [ordered]@{
    '@type' = 'WebSite'
    '@id' = $site + '#website'
    url = $site
    name = 'Hipnoterapi Center'
    alternateName = 'Hipnoterapi Lampung'
    inLanguage = 'id-ID'
    publisher = @{ '@id' = $site + '#klinik' }
  },
  [ordered]@{
    '@type' = 'FAQPage'
    '@id' = $site + '#faq'
    inLanguage = 'id-ID'
    mainEntity = $qa
  }
)
$json = ([ordered]@{ '@context' = 'https://schema.org'; '@graph' = $graph } | ConvertTo-Json -Depth 12 -Compress)
# hindari penutupan tag script di dalam JSON
$json = $json.Replace('</', '<\/')
$block = "<!--SCHEMA-->`n<script type=`"application/ld+json`">$json</script>`n<!--/SCHEMA-->"
$new = [regex]::Replace($html, '(?s)<!--SCHEMA-->.*?<!--/SCHEMA-->', [Text.RegularExpressions.MatchEvaluator]{ param($m) $block })
[IO.File]::WriteAllText($file, $new, (New-Object Text.UTF8Encoding $false))
Write-Host "Schema diperbarui: $($qa.Count) tanya-jawab FAQ."
