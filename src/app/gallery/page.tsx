'use client';
import React from 'react';
import './Gallery.css';
import Wrapper from '@/components/basic/wrapper';
import SafeArea from '@/components/basic/safe-area';
import { photos_cabildos, photos_festivals } from '@/constants';

const Gallery: React.FC = () => {
    const [isMobile, setIsMobile] = React.useState(false);
    const sectionColor = '#2E585B';
    const sectionTextColor = '#FFFFFF';
    const footerColor = '#FFFFFF';
    const [selectedIndex, setSelectedIndex] = React.useState<number | null>(null);
    const [selectedTab, setSelectedTab] = React.useState<'cabildos' | 'festivales'>('cabildos');
    const currentPhoto = selectedIndex !== null ? (selectedTab === 'cabildos' ? photos_cabildos : photos_festivals)[selectedIndex] : null;

    // videos
    const videoRef = React.useRef<HTMLVideoElement>(null);
    const videoRefMobile = React.useRef<HTMLVideoElement>(null);
    const [showOverlay, setShowOverlay] = React.useState(true);
    const [fadeOut, setFadeOut] = React.useState(false);

    const handleOverlayClick = () => {
        setFadeOut(true);
        setTimeout(() => {
            setShowOverlay(false);
            isMobile ? videoRefMobile.current?.play() : videoRef.current?.play();
        }, 500);
    };


    React.useEffect(() => {
        if (typeof window === 'undefined') return;

        const checkMobile = () => {
            setIsMobile(window.innerWidth < 768);
        };

        checkMobile(); // Initial check

        window.addEventListener('resize', checkMobile);
        return () => window.removeEventListener('resize', checkMobile);
    }, []);

    const goPrev = () => {
        if (selectedIndex !== null && selectedIndex > 0) {
            setSelectedIndex(selectedIndex - 1);
        }
    };

    const goNext = () => {
        if (selectedIndex !== null && selectedIndex < (selectedTab === 'cabildos' ? photos_cabildos.length : photos_festivals.length) - 1) {
            setSelectedIndex(selectedIndex + 1);
        }
    };
    return (
        <>
            <Wrapper
                color={sectionColor}
                textColor={sectionTextColor}
                hasFooter
                footerColor={footerColor}
                logoColor={sectionTextColor}
            >
                <>
                    {/* <div className="gallery-header">
                        <SafeArea>
                            <div className='d-flex flex-row w100 gap'>
                                <div className="gallery-p1 thunder-fw-bold-lc">GALERÍA</div>
                            </div>
                        </SafeArea>
                    </div> */}
                    <div className='gallery-content'>
                        <SafeArea>
                            <>
                                {currentPhoto && (
                                    <div className="photo-modal" onClick={() => setSelectedIndex(null)}>
                                        {selectedIndex !== null && selectedIndex > 0 && (
                                            <button className="photo-nav left" onClick={(e) => { e.stopPropagation(); goPrev(); }}>←</button>
                                        )}
                                        <img src={currentPhoto.url} alt="Zoomed" className="photo-modal-image" />
                                        {selectedIndex !== null && selectedIndex < (selectedTab === 'cabildos' ? photos_cabildos.length : photos_festivals.length) - 1 && (
                                            <button className="photo-nav right" onClick={(e) => { e.stopPropagation(); goNext(); }}>→</button>
                                        )}
                                    </div>
                                )}
                                <div className="d-flex flex-row gallery-titles-container">
                                    <div className={`textWhite gallery-tab-title pointer ${selectedTab === 'cabildos' ? 'thunder-fw-bold-lc' : 'thunder-fw-lc'} uppercase`} onClick={() => setSelectedTab('cabildos')}>Cabildos</div>
                                    <div className={`textWhite gallery-tab-title pointer ${selectedTab === 'festivales' ? 'thunder-fw-bold-lc' : 'thunder-fw-lc'} uppercase`} onClick={() => setSelectedTab('festivales')}>Festivales</div>
                                </div>
                                <div className="gallery-divider" />
                                <div className="photo-grid gap w100">
                                    {selectedTab === 'cabildos' ? photos_cabildos.map((photo, index) => (
                                        <img
                                            key={photo.id}
                                            src={photo.url}
                                            alt="gallery-image"
                                            className="gallery-image mb8 pointer"
                                            onClick={() => setSelectedIndex(index)}
                                        />
                                    )) : photos_festivals.map((photo, index) => (
                                        <img
                                            key={photo.id}
                                            src={photo.url}
                                            alt="gallery-image"
                                            className="gallery-image mb8 pointer"
                                            onClick={() => setSelectedIndex(index)}
                                        />
                                    ))}
                                </div>
                            </>
                        </SafeArea>
                    </div>
                    <div className="talk-cabildos">
                        <SafeArea>
                            <>
                                {!isMobile && <div className="c-video-desktop-wrapper">
                                    {showOverlay && (
                                        <div
                                            className={`video-overlay ${fadeOut ? 'hidden' : ''}`}
                                            onClick={handleOverlayClick}
                                        />
                                    )}
                                    <video
                                        ref={videoRef}
                                        className="c-video-desktop"
                                        src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/habla.mp4"
                                        controls
                                    />
                                </div>}
                            </>
                        </SafeArea>
                    </div>
                    {isMobile && <div className='talk-video-mobile'>
                        {showOverlay && (
                            <div
                                className={`video-overlay-mobile ${fadeOut ? 'fade-out' : ''}`}
                                onClick={handleOverlayClick}
                            />
                        )}
                        <video
                            ref={videoRefMobile}
                            className="c-video-mobile"
                            src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/habla.mp4"
                            controls
                        />
                    </div>}
                </>
            </Wrapper >
        </>
    )
}
export default Gallery;