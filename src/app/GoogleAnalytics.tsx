// app/GoogleAnalytics.tsx
"use client";

import Script from "next/script";
import { useEffect } from "react";
import { usePathname } from "next/navigation";

const GA_MEASUREMENT_ID = "G-28KM9YWSXP";

export default function GoogleAnalytics() {
    const pathname = usePathname();

    // Send page_view on client-side navigation
    useEffect(() => {
        if (!pathname) return;
        const url = pathname;
        // @ts-ignore
        window.gtag?.("config", GA_MEASUREMENT_ID, { page_path: url });
    }, [pathname]);

    return (
        <>
            {/* gtag.js loader */}
            <Script
                id="ga-loader"
                src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
                strategy="afterInteractive"
            />
            {/* init */}
            <Script id="ga-init" strategy="afterInteractive">
                {`
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          window.gtag = gtag;
          gtag('js', new Date());
          gtag('config', '${GA_MEASUREMENT_ID}');
        `}
            </Script>
        </>
    );
}
