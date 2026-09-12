'use client';
import React from 'react';
import './Directory.css';
import Wrapper from '@/components/basic/wrapper';
import SafeArea from '@/components/basic/safe-area';
import { BackArrowSVG, FbSVG, ForwardArrowSVG, IgSVG, SearchSVG } from '@/constants/svgs';
import { companies } from '@/constants';
import AllOrgsPopUp from '@/components/sections/gallery/AllOrgsPopUp';

const Directory: React.FC = () => {
    const [inputFocused, setInputFocused] = React.useState<boolean>(false);
    const sectionColor = '#FFFFFF';
    const sectionTextColor = '#2E585B';
    const [orgs, setOrgs] = React.useState(companies);
    const [search, setSearch] = React.useState('');
    const ITEMS_PER_PAGE_DESKTOP = 4;
    const ITEMS_PER_PAGE_MOBILE = 1;
    const [startIndex, setStartIndex] = React.useState(0);
    const [openModal, setOpenModal] = React.useState<boolean>(false);

    const handleSearch = (e: any) => {
        const value = e.target.value;
        setSearch(value);

        if (value.length >= 3) {
            const filtered = companies.filter(c =>
                // c.keywords?.includes(value.toLowerCase()) ||
                c.name_company.toLowerCase().includes(value.toLowerCase())
            );
            setOrgs(filtered);
            setStartIndex(0);
        }
    };

    const handleForwardDesktop = () => {
        if (startIndex + ITEMS_PER_PAGE_DESKTOP < orgs.length) {
            setStartIndex(startIndex + ITEMS_PER_PAGE_DESKTOP);
        }
    };

    const handleBackDesktop = () => {
        if (startIndex - ITEMS_PER_PAGE_DESKTOP >= 0) {
            setStartIndex(startIndex - ITEMS_PER_PAGE_DESKTOP);
        }
    };

    const handleForwardMobile = () => {
        if (startIndex + ITEMS_PER_PAGE_MOBILE < orgs.length) {
            setStartIndex(startIndex + ITEMS_PER_PAGE_MOBILE);
        }
    };

    const handleBackMobile = () => {
        if (startIndex - ITEMS_PER_PAGE_MOBILE >= 0) {
            setStartIndex(startIndex - ITEMS_PER_PAGE_MOBILE);
        }
    };

    React.useEffect(() => {
        if (search.length >= 3) {
            const filtered = companies.filter(c =>
                // c.keywords?.includes(search.toLowerCase()) ||
                c.name_company.toLowerCase().includes(search.toLowerCase())
            );
            setOrgs(filtered);
        } else {
            setOrgs(companies); // Reset when search is too short
        }
    }, [search]);

    return (
        <>
            <Wrapper
                color={sectionColor}
                textColor={sectionTextColor}
                hasFooter
                logoColor={sectionTextColor}
            >
                <>
                    <>
                        {openModal && <AllOrgsPopUp close={() => setOpenModal(false)} />}
                        <div className="directory-header">
                            <SafeArea>
                                <div className='d-flex flex-row w100 gap'>
                                    <div className='directory-p1'>
                                        <div className='fw400 directory-header-text'>Siempre pensamos que a nadie le importa lo que pasa en el Perú.</div>
                                        <div className='fw400 directory-header-text'>Y sí, hay cosas que están mal. Pero también hay un montón de gente chévere en todo el país haciendo algo para cambiarlas.</div>
                                        <div className='fw400 directory-header-text-mobile'>Siempre pensamos que a nadie le importa lo que pasa en el Perú.</div>
                                        <div className='fw400 directory-header-text-mobile'>Y sí, hay cosas que están mal.</div>
                                        <div className='fw400 directory-header-text-mobile'>Pero también hay un montón de gente chévere en todo el país haciendo algo para cambiarlas.</div>
                                    </div>
                                    <div className='directory-p2' />
                                </div>
                            </SafeArea>
                            <img src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/bg/bg_directory.png" alt="directory bg" className="directory-header-bg" />
                            <img src="https://ya-toca-web-imgs.nyc3.cdn.digitaloceanspaces.com/bg/bg_directory_mobile.png" alt="directory bg mobile" className="directory-header-bg-mobile" />
                        </div>
                        <div className="directory-footer-text">
                            <SafeArea>
                                <div className='d-flex flex-row w100 gap'>
                                    <div className="directory-text-p1" />
                                    <div className="directory-text-p2">
                                        <div>Échales un ojo. Súmate. De todas maneras, hay algo que te mueve.</div>
                                        <div>
                                            El Perú que queremos se construye juntos.
                                            Uno donde sí den ganas de quedarse.
                                        </div>
                                    </div>
                                </div>
                            </SafeArea>
                        </div>
                        <div className="directory-content">
                            <SafeArea>
                                <>
                                    <div className="directory-title uppercase thunder-fw-bold-lc">Directorio</div>
                                    <div className='d-flex flex-row w100 directory-search aic'>
                                        <div className="directory-search-content w100">
                                            <div className="directory-search-input-icon"><SearchSVG /></div>
                                            <input onFocus={() => setInputFocused(true)}
                                                onBlur={() => setInputFocused(false)}
                                                onChange={handleSearch}
                                                className='directory-search-input-desktop'
                                                placeholder="ESCRIBE AQUÍ EL NOMBRE DE LA ORGANIZACIÓN QUE BUSCAS..."
                                            />
                                            <input onFocus={() => setInputFocused(true)}
                                                onBlur={() => setInputFocused(false)}
                                                onChange={handleSearch}
                                                className='directory-search-input-mobile'
                                                placeholder="ESCRIBE AQUÍ EL NOMBRE DE LA ORGA..."
                                            />
                                        </div>
                                        <div className='d-flex flex-row w100 directory-search-content-arrows-desktop'>
                                            <div className={`directory-search-arrow-back w100 ${inputFocused ? 'focused' : ''}`} onClick={handleBackDesktop}><BackArrowSVG /></div>
                                            <div className={`directory-search-arrow-forward w100 ${inputFocused ? 'focused' : ''}`} onClick={handleForwardDesktop}><ForwardArrowSVG /></div>
                                        </div>
                                        <div className='d-flex flex-row w100 directory-search-content-arrows-mobile'>
                                            <div className={`directory-search-arrow-back w100 ${inputFocused ? 'focused' : ''}`} onClick={handleBackMobile}><BackArrowSVG /></div>
                                            <div className={`directory-search-arrow-forward w100 ${inputFocused ? 'focused' : ''}`} onClick={handleForwardMobile}><ForwardArrowSVG /></div>
                                        </div>
                                    </div>
                                    <div className="d-flex flex-row gap10 aic mt12">
                                        <div className="counter-desktop">{(startIndex / ITEMS_PER_PAGE_DESKTOP + 1) * ITEMS_PER_PAGE_DESKTOP}/{orgs.length}</div>
                                        <div className="counter-mobile tac">{(startIndex / ITEMS_PER_PAGE_MOBILE + 1) * ITEMS_PER_PAGE_MOBILE}/{orgs.length}</div>
                                        <div className="fw700 fs16 pointer" onClick={() => setOpenModal(true)}>Ver todo</div>
                                    </div>
                                </>
                            </SafeArea>
                        </div>
                        <div className="directory-content-companies">
                            <SafeArea>
                                <>
                                    <div className='d-flex flex-row w100 gap directory-content-companies-list-desktop'>
                                        {orgs.length === 0 && (
                                            <div className="directory-content-company">
                                                <div className="directory-content-company-name uppercase thunder-fw-bold-lc">No se encontraron resultados.</div>
                                            </div>
                                        )}
                                        {orgs.slice(startIndex, startIndex + ITEMS_PER_PAGE_DESKTOP).map((company, index) => (
                                            <div key={company.id} className="directory-content-company fade-in">
                                                <div className="directory-content-company-name uppercase thunder-fw-bold-lc">{company.name_company}</div>
                                                <div className="directory-content-company-title">{company.description}</div>
                                                <div className="d-flex flex-row jcsb w100">
                                                    {company.email ? <div className="directory-content-company-email fw700">
                                                        <a href={`mailto:${company.email}`}>Correo</a>
                                                    </div> : <div />}
                                                    <div>
                                                        {company.phones?.map((phone, index) => (
                                                            <div key={index} className="directory-content-company-phone fw700">{phone}</div>
                                                        ))}
                                                    </div>
                                                </div>
                                                {company.networks && <div className="fw700 mt16">
                                                    <a href={company.networks} target="_blank">{company.networks.includes('facebook') ? <FbSVG /> : <IgSVG />}</a>
                                                </div>}
                                            </div>
                                        ))}
                                    </div>
                                    <div className='d-flex flex-row w100 gap directory-content-companies-list-mobile'>
                                        {orgs.length === 0 && (
                                            <div className="directory-content-company">
                                                <div className="directory-content-company-name uppercase thunder-fw-bold-lc">No se encontraron resultados.</div>
                                            </div>
                                        )}
                                        {orgs.slice(startIndex, startIndex + ITEMS_PER_PAGE_MOBILE).map((company, index) => (
                                            <div key={company.id} className="directory-content-company company-mobile fade-in">
                                                <div className="directory-content-company-name uppercase thunder-fw-bold-lc">{company.name_company}</div>
                                                <div className="directory-content-company-title">{company.description}</div>
                                                <div className="d-flex flex-col aic w100 content-mobile">
                                                    {company.email && <div className="directory-content-company-email fw700" style={{ width: 'fit-content' }}>
                                                        <a href={`mailto:${company.email}`}>Correo</a>
                                                    </div>}
                                                    {company.networks && <div className="directory-content-company-email fw700" style={{ width: 'fit-content' }}>
                                                        <a href={company.networks} target="_blank">Redes</a>
                                                    </div>}
                                                    <div style={{ minHeight: 35 }} />
                                                    <div>
                                                        {company.phones?.map((phone, index) => (
                                                            <div key={index} className="directory-content-company-phone fw700">{phone}</div>
                                                        ))}
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </>
                            </SafeArea>
                        </div>
                    </>
                </>
            </Wrapper >
        </>
    )
}
export default Directory;